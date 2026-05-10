/**
 * Session Browser extension.
 *
 * Adds `/sessions` for discovering saved Pi sessions. The default view lists
 * all known sessions. Enter opens the highlighted session. Space toggles the
 * highlighted session for multi-delete; once at least one session is selected,
 * press `d` or Delete to delete all selected sessions.
 */

import type { ExtensionAPI, ExtensionCommandContext, SessionInfo } from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { spawnSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { unlink } from "node:fs/promises";
import { basename, resolve } from "node:path";

const STATUS_KEY = "session-browser";
const MAX_VISIBLE_SESSIONS = 12;

type Scope = "all" | "current";

type BrowserResult =
	| { action: "open"; session: SessionInfo }
	| { action: "delete"; sessions: SessionInfo[] };

type DeleteMethod = "trash" | "unlink" | "missing";

interface DeleteResult {
	path: string;
	ok: boolean;
	method: DeleteMethod;
	error?: string;
}

type StatusMessage = { type: "info" | "warning" | "error"; text: string };

type ThemeLike = {
	fg: (color: any, text: string) => string;
	bg: (color: any, text: string) => string;
	bold: (text: string) => string;
};

export default function (pi: ExtensionAPI) {
	pi.registerCommand("sessions", {
		description: "Browse sessions. Enter opens, Space selects for deletion, d/Delete deletes selected.",
		handler: async (args, ctx) => {
			await ctx.waitForIdle();

			if (!ctx.hasUI) return;

			const scope = parseScope(args);
			const sessions = await loadSessions(ctx, scope);
			if (sessions.length === 0) {
				ctx.ui.notify(scope === "all" ? "No saved sessions found" : "No saved sessions for this project", "info");
				return;
			}

			const result = await showSessionBrowser(ctx, sessions, scope);
			if (!result) return;

			if (result.action === "open") {
				await openSession(ctx, result.session);
				return;
			}

			await deleteSelectedSessions(ctx, result.sessions);
		},
	});
}

function parseScope(args: string): Scope {
	const tokens = args
		.toLowerCase()
		.split(/\s+/)
		.map((token) => token.trim())
		.filter(Boolean);

	if (tokens.some((token) => token === "current" || token === "project" || token === "cwd")) {
		return "current";
	}
	return "all";
}

async function loadSessions(ctx: ExtensionCommandContext, scope: Scope): Promise<SessionInfo[]> {
	ctx.ui.setStatus(STATUS_KEY, "sessions: loading…");
	const onProgress = (loaded: number, total: number) => {
		if (total > 0) ctx.ui.setStatus(STATUS_KEY, `sessions: ${loaded}/${total}`);
	};

	try {
		return scope === "all"
			? await SessionManager.listAll(onProgress)
			: await SessionManager.list(ctx.cwd, ctx.sessionManager.getSessionDir(), onProgress);
	} finally {
		ctx.ui.setStatus(STATUS_KEY, undefined);
	}
}

async function showSessionBrowser(
	ctx: ExtensionCommandContext,
	sessions: SessionInfo[],
	scope: Scope,
): Promise<BrowserResult | undefined> {
	const currentPath = ctx.sessionManager.getSessionFile();
	const currentNormalizedPath = currentPath ? normalizePath(currentPath) : undefined;

	return ctx.ui.custom<BrowserResult | undefined>((tui, theme: ThemeLike, keybindings, done) => {
		let selectedIndex = 0;
		let status: StatusMessage | undefined;
		let cachedWidth: number | undefined;
		let cachedLines: string[] | undefined;
		const selectedForDeletion = new Set<string>();

		function invalidate() {
			cachedWidth = undefined;
			cachedLines = undefined;
		}

		function refresh() {
			invalidate();
			tui.requestRender();
		}

		function setStatus(type: StatusMessage["type"], text: string) {
			status = { type, text };
			refresh();
		}

		function selectedSession(): SessionInfo | undefined {
			return sessions[selectedIndex];
		}

		function isCurrentSessionInfo(session: SessionInfo): boolean {
			return !!currentNormalizedPath && normalizePath(session.path) === currentNormalizedPath;
		}

		function toggleSelectedForDeletion() {
			const session = selectedSession();
			if (!session) return;

			if (isCurrentSessionInfo(session)) {
				setStatus("warning", "Cannot select the active session for deletion");
				return;
			}

			const key = normalizePath(session.path);
			if (selectedForDeletion.has(key)) {
				selectedForDeletion.delete(key);
				status = undefined;
			} else {
				selectedForDeletion.add(key);
				status = undefined;
			}
			refresh();
		}

		function selectedSessionsForDeletion(): SessionInfo[] {
			return sessions.filter(
				(session) => selectedForDeletion.has(normalizePath(session.path)) && !isCurrentSessionInfo(session),
			);
		}

		function requestDeleteSelected() {
			const selected = selectedSessionsForDeletion();
			if (selected.length === 0) {
				setStatus("warning", "Select one or more sessions with Space before deleting");
				return;
			}
			done({ action: "delete", sessions: selected });
		}

		function openHighlighted() {
			const session = selectedSession();
			if (!session) return;
			done({ action: "open", session });
		}

		function moveSelection(delta: number) {
			selectedIndex = Math.max(0, Math.min(sessions.length - 1, selectedIndex + delta));
			status = undefined;
			refresh();
		}

		function handleInput(data: string) {
			if (keybindings.matches(data, "tui.select.up") || matchesKey(data, Key.up)) {
				moveSelection(-1);
				return;
			}
			if (keybindings.matches(data, "tui.select.down") || matchesKey(data, Key.down)) {
				moveSelection(1);
				return;
			}
			if (keybindings.matches(data, "tui.select.pageUp") || matchesKey(data, Key.pageUp)) {
				moveSelection(-MAX_VISIBLE_SESSIONS);
				return;
			}
			if (keybindings.matches(data, "tui.select.pageDown") || matchesKey(data, Key.pageDown)) {
				moveSelection(MAX_VISIBLE_SESSIONS);
				return;
			}
			if (keybindings.matches(data, "tui.select.confirm") || matchesKey(data, Key.enter)) {
				openHighlighted();
				return;
			}
			if (matchesKey(data, Key.space)) {
				toggleSelectedForDeletion();
				return;
			}
			if (isDeleteKey(data)) {
				requestDeleteSelected();
				return;
			}
			if (keybindings.matches(data, "tui.select.cancel") || matchesKey(data, Key.escape)) {
				done(undefined);
			}
		}

		function render(width: number): string[] {
			if (cachedLines && cachedWidth === width) return cachedLines;

			const lines: string[] = [];
			const selectedCount = selectedForDeletion.size;
			const selectedDeleteText =
				selectedCount > 0
					? theme.fg("success", `d/Delete delete selected (${selectedCount})`)
					: theme.fg("dim", "d/Delete delete selected (disabled)");
			const add = (line = "") => lines.push(truncateToWidth(line, width, "…"));

			add(theme.fg("accent", "─".repeat(width)));
			add(
				`${theme.fg("accent", theme.bold("Sessions"))} ${theme.fg("dim", `${sessions.length} found`)} ${theme.fg(
					"muted",
					scope === "all" ? "all projects" : "current project",
				)}`,
			);
			add(`${theme.fg("dim", "↑↓ navigate · Enter open · Space select · ")}${selectedDeleteText}${theme.fg("dim", " · Esc cancel")}`);
			if (status) {
				add(theme.fg(status.type === "error" ? "error" : status.type === "warning" ? "warning" : "accent", status.text));
			} else {
				add("");
			}

			const startIndex = Math.max(
				0,
				Math.min(selectedIndex - Math.floor(MAX_VISIBLE_SESSIONS / 2), sessions.length - MAX_VISIBLE_SESSIONS),
			);
			const endIndex = Math.min(startIndex + MAX_VISIBLE_SESSIONS, sessions.length);

			for (let i = startIndex; i < endIndex; i++) {
				const session = sessions[i]!;
				add(
					formatSessionRow(
						session,
						i,
						selectedIndex === i,
						selectedForDeletion.has(normalizePath(session.path)),
						isCurrentSessionInfo(session),
						scope,
						theme,
						width,
					),
				);
			}

			if (startIndex > 0 || endIndex < sessions.length) {
				add(theme.fg("muted", `  (${selectedIndex + 1}/${sessions.length})`));
			}
			add(theme.fg("accent", "─".repeat(width)));

			cachedWidth = width;
			cachedLines = lines;
			return lines;
		}

		return { render, invalidate, handleInput };
	});
}

function formatSessionRow(
	session: SessionInfo,
	index: number,
	isHighlighted: boolean,
	isMarkedForDeletion: boolean,
	isCurrent: boolean,
	scope: Scope,
	theme: ThemeLike,
	width: number,
): string {
	const cursor = isHighlighted ? theme.fg("accent", "› ") : "  ";
	const checkbox = isCurrent
		? theme.fg("warning", "●")
		: isMarkedForDeletion
			? theme.fg("success", "☑")
			: theme.fg("dim", "☐");
	const title = truncateToWidth(sessionTitle(session).replace(/[\x00-\x1f\x7f]/g, " "), 80, "…");
	const titleColor = isCurrent ? "warning" : isMarkedForDeletion ? "success" : isHighlighted ? "accent" : "text";
	const styledTitle = isHighlighted ? theme.bold(theme.fg(titleColor, title)) : theme.fg(titleColor, title);
	const rawLeft = `${cursor}${checkbox} ${index + 1}. ${styledTitle}`;
	const current = isCurrent ? " · current" : "";
	const project = scope === "all" ? ` · ${formatProject(session.cwd)}` : "";
	const right = `${session.messageCount} msg · ${formatAge(session.modified)} · ${session.id.slice(0, 8)}${project}${current}`;
	const styledRight = theme.fg(isCurrent ? "warning" : "dim", right);
	const rightWidth = visibleWidth(styledRight);
	const left = truncateToWidth(rawLeft, Math.max(1, width - rightWidth - 1), "…");
	const gap = Math.max(1, width - visibleWidth(left) - rightWidth);
	const row = `${left}${" ".repeat(gap)}${styledRight}`;
	const clipped = truncateToWidth(row, width, "…");
	return isHighlighted ? theme.bg("selectedBg", clipped) : clipped;
}

function isDeleteKey(data: string): boolean {
	return (
		data === "d" ||
		data === "D" ||
		matchesKey(data, "d") ||
		matchesKey(data, Key.shift("d")) ||
		matchesKey(data, Key.delete)
	);
}

async function openSession(ctx: ExtensionCommandContext, session: SessionInfo): Promise<void> {
	if (isCurrentSession(ctx, session.path)) {
		ctx.ui.notify("That session is already active", "info");
		return;
	}

	const result = await ctx.switchSession(session.path, {
		withSession: async (nextCtx) => {
			nextCtx.ui.notify(`Switched to ${sessionTitle(session)}`, "info");
		},
	});

	if (result.cancelled) {
		ctx.ui.notify("Session switch cancelled", "info");
	}
}

async function deleteSelectedSessions(ctx: ExtensionCommandContext, selectedSessions: SessionInfo[]): Promise<void> {
	const deletable = selectedSessions.filter((session) => !isCurrentSession(ctx, session.path));
	const skipped = selectedSessions.length - deletable.length;

	if (deletable.length === 0) {
		ctx.ui.notify(skipped > 0 ? "Only the active session was selected; it was not deleted" : "No sessions to delete", "info");
		return;
	}

	const preview = deletable
		.slice(0, 5)
		.map((session) => `• ${sessionTitle(session)} (${formatProject(session.cwd)}, ${session.id.slice(0, 8)})`)
		.join("\n");
	const more = deletable.length > 5 ? `\n• …and ${deletable.length - 5} more` : "";
	const confirmed = await ctx.ui.confirm(
		"Delete selected sessions?",
		[
			`This will delete ${deletable.length} selected session${deletable.length === 1 ? "" : "s"}.`,
			skipped > 0 ? `${skipped} active session${skipped === 1 ? "" : "s"} will be skipped.` : undefined,
			"",
			preview + more,
			"",
			"Pi will use the `trash` CLI when available; otherwise it permanently deletes the .jsonl files.",
		]
			.filter((line): line is string => line !== undefined)
			.join("\n"),
	);
	if (!confirmed) return;

	const results: DeleteResult[] = [];
	try {
		for (let i = 0; i < deletable.length; i++) {
			const session = deletable[i]!;
			ctx.ui.setStatus(STATUS_KEY, `deleting: ${i + 1}/${deletable.length}`);
			results.push(await deleteSessionFile(session.path));
		}
	} finally {
		ctx.ui.setStatus(STATUS_KEY, undefined);
	}

	const deleted = results.filter((result) => result.ok).length;
	const failed = results.filter((result) => !result.ok);
	const movedToTrash = results.filter((result) => result.ok && result.method === "trash").length;
	const permanentlyDeleted = results.filter((result) => result.ok && result.method === "unlink").length;

	if (failed.length === 0) {
		ctx.ui.notify(
			`Deleted ${deleted} session${deleted === 1 ? "" : "s"}` +
				(movedToTrash > 0 || permanentlyDeleted > 0
					? ` (${movedToTrash} trash, ${permanentlyDeleted} permanent)`
					: ""),
			"info",
		);
		return;
	}

	ctx.ui.notify(
		`Deleted ${deleted}/${deletable.length} sessions; ${failed.length} failed. First error: ${failed[0]?.error ?? "unknown"}`,
		"warning",
	);
}

function sessionTitle(session: SessionInfo): string {
	return (session.name?.trim() || session.firstMessage || "(no messages)").replace(/\s+/g, " ").trim();
}

function formatProject(cwd: string): string {
	if (!cwd) return "unknown cwd";
	return basename(cwd) || cwd;
}

function formatAge(date: Date): string {
	const diffMs = Date.now() - date.getTime();
	const minutes = Math.floor(diffMs / 60_000);
	const hours = Math.floor(diffMs / 3_600_000);
	const days = Math.floor(diffMs / 86_400_000);

	if (minutes < 1) return "now";
	if (minutes < 60) return `${minutes}m ago`;
	if (hours < 24) return `${hours}h ago`;
	if (days < 30) return `${days}d ago`;
	if (days < 365) return `${Math.floor(days / 30)}mo ago`;
	return `${Math.floor(days / 365)}y ago`;
}

function isCurrentSession(ctx: ExtensionCommandContext, sessionPath: string): boolean {
	const current = ctx.sessionManager.getSessionFile();
	return !!current && normalizePath(current) === normalizePath(sessionPath);
}

function normalizePath(path: string): string {
	let normalized = resolve(path);
	try {
		normalized = realpathSync(normalized);
	} catch {
		// File may have disappeared between discovery and action; fall back to the resolved path.
	}
	return process.platform === "win32" ? normalized.toLowerCase() : normalized;
}

async function deleteSessionFile(sessionPath: string): Promise<DeleteResult> {
	if (!existsSync(sessionPath)) {
		return { path: sessionPath, ok: true, method: "missing" };
	}

	const trashArgs = sessionPath.startsWith("-") ? ["--", sessionPath] : [sessionPath];
	const trashResult = spawnSync("trash", trashArgs, { encoding: "utf-8" });

	if (trashResult.status === 0 || !existsSync(sessionPath)) {
		return { path: sessionPath, ok: true, method: "trash" };
	}

	try {
		await unlink(sessionPath);
		return { path: sessionPath, ok: true, method: "unlink" };
	} catch (error) {
		const unlinkError = error instanceof Error ? error.message : String(error);
		const trashError = getTrashError(trashResult);
		return {
			path: sessionPath,
			ok: false,
			method: "unlink",
			error: trashError ? `${unlinkError} (${trashError})` : unlinkError,
		};
	}
}

function getTrashError(result: ReturnType<typeof spawnSync>): string | undefined {
	const parts: string[] = [];
	if (result.error) parts.push(result.error.message);
	const stderr = result.stderr ? String(result.stderr).trim() : "";
	if (stderr) parts.push(stderr.split("\n")[0] ?? stderr);
	if (parts.length === 0) return undefined;
	return `trash: ${parts.join(" · ").slice(0, 200)}`;
}
