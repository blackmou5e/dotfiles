/**
 * Auto-loaded Pi status-line extension.
 *
 * Location matters: ~/.pi/agent/extensions/*.ts is auto-discovered by Pi.
 * In this dotfiles repo, `pi/` is linked to ~/.pi, so this file becomes
 * ~/.pi/agent/extensions/status-line.ts after `make link` / `make install`.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { basename } from "node:path";

type Mode = "idle" | "thinking" | "tools";
type ThemeLike = {
	fg: (color: any, text: string) => string;
	bold: (text: string) => string;
};

const STATUS_LINE_ID = "custom-status-line";

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let requestRender: (() => void) | undefined;
	let ticker: ReturnType<typeof setInterval> | undefined;

	const state = {
		mode: "idle" as Mode,
		turn: 0,
		activeTools: 0,
		completedTools: 0,
		lastTool: "",
		startedAt: 0,
		lastDurationMs: 0,
	};

	function refresh() {
		requestRender?.();
	}

	function startTicker() {
		if (ticker) return;
		ticker = setInterval(refresh, 1000);
		ticker.unref?.();
	}

	function stopTicker() {
		if (!ticker) return;
		clearInterval(ticker);
		ticker = undefined;
	}

	function resetState() {
		state.mode = "idle";
		state.turn = 0;
		state.activeTools = 0;
		state.completedTools = 0;
		state.lastTool = "";
		state.startedAt = 0;
		state.lastDurationMs = 0;
	}

	function formatMode(theme: ThemeLike): string {
		const elapsed = state.startedAt && state.mode !== "idle" ? formatDuration(Date.now() - state.startedAt) : "";

		if (state.mode === "tools") {
			const active = state.activeTools > 1 ? `×${state.activeTools}` : "";
			const tool = state.lastTool ? ` ${state.lastTool}` : "";
			return theme.fg("warning", `tools${active}`) + theme.fg("dim", tool);
		}

		if (state.mode === "thinking") {
			return theme.fg("accent", "thinking") + (elapsed ? theme.fg("dim", ` ${elapsed}`) : "");
		}

		const last = state.lastDurationMs ? ` last ${formatDuration(state.lastDurationMs)}` : "";
		return theme.fg("success", "ready") + theme.fg("dim", last);
	}

	function formatThinking(theme: ThemeLike): string {
		return theme.fg("dim", `think:${pi.getThinkingLevel()}`);
	}

	function formatProgress(theme: ThemeLike): string | undefined {
		const parts = [];
		if (state.turn > 0) parts.push(`turn:${state.turn}`);
		if (state.completedTools > 0) parts.push(`tools:${state.completedTools}`);
		return parts.length > 0 ? theme.fg("dim", parts.join(" ")) : undefined;
	}

	function installFooter(ctx: ExtensionContext) {
		if (!ctx.hasUI || !enabled) return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			const thisRequestRender = () => tui.requestRender();
			requestRender = thisRequestRender;
			const disposeBranchListener = footerData.onBranchChange(thisRequestRender);

			return {
				dispose() {
					disposeBranchListener();
					if (requestRender === thisRequestRender) requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const separator = theme.fg("dim", " │ ");
					const project = basename(ctx.cwd) || ctx.cwd;
					const branch = footerData.getGitBranch();
					const sessionName = pi.getSessionName();

					const left = joinParts(
						[
							theme.fg("accent", theme.bold("π")),
							formatMode(theme),
							formatProgress(theme),
							theme.fg("muted", project),
							branch ? theme.fg("dim", `git:${branch}`) : undefined,
							sessionName ? theme.fg("dim", `#${sessionName}`) : undefined,
							formatExternalStatuses(footerData, theme),
						],
						separator,
					);

					const right = joinParts(
						[
							formatModel(ctx, theme),
							formatThinking(theme),
							formatContext(ctx, theme),
							formatTotals(ctx, theme),
						],
						separator,
					);

					return [placeLeftRight(left, right, width)];
				},
			};
		});
		refresh();
	}

	function uninstallFooter(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		ctx.ui.setFooter(undefined);
		requestRender = undefined;
	}

	pi.on("session_start", async (_event, ctx) => {
		resetState();
		installFooter(ctx);
	});

	pi.on("agent_start", async () => {
		state.mode = "thinking";
		state.startedAt = Date.now();
		state.lastDurationMs = 0;
		startTicker();
		refresh();
	});

	pi.on("turn_start", async (event) => {
		state.mode = "thinking";
		state.turn = event.turnIndex + 1;
		refresh();
	});

	pi.on("tool_execution_start", async (event) => {
		state.mode = "tools";
		state.activeTools++;
		state.lastTool = event.toolName;
		refresh();
	});

	pi.on("tool_execution_end", async (event) => {
		state.activeTools = Math.max(0, state.activeTools - 1);
		state.completedTools++;
		state.lastTool = event.toolName;
		state.mode = state.activeTools > 0 ? "tools" : "thinking";
		refresh();
	});

	pi.on("agent_end", async () => {
		state.mode = "idle";
		state.lastDurationMs = state.startedAt ? Date.now() - state.startedAt : 0;
		state.startedAt = 0;
		state.activeTools = 0;
		stopTicker();
		refresh();
	});

	pi.on("model_select", async () => refresh());
	pi.on("thinking_level_select", async () => refresh());

	pi.on("session_shutdown", async (_event, ctx) => {
		stopTicker();
		uninstallFooter(ctx);
	});

	pi.registerCommand("status-line", {
		description: "Toggle the custom auto-loaded status line for this session",
		handler: async (args, ctx) => {
			const normalized = args.trim().toLowerCase();
			enabled = normalized === "on" ? true : normalized === "off" ? false : !enabled;

			if (enabled) {
				installFooter(ctx);
				ctx.ui.notify("Custom status line enabled", "info");
			} else {
				uninstallFooter(ctx);
				ctx.ui.notify("Custom status line disabled", "info");
			}
		},
	});
}

function joinParts(parts: Array<string | undefined>, separator: string): string {
	return parts.filter((part): part is string => Boolean(part)).join(separator);
}

function formatModel(ctx: ExtensionContext, theme: ThemeLike): string | undefined {
	const model = ctx.model as { provider?: string; id?: string } | undefined;
	if (!model?.id) return theme.fg("warning", "no model");
	const provider = model.provider ? `${model.provider}/` : "";
	return theme.fg("dim", provider + model.id);
}

function formatContext(ctx: ExtensionContext, theme: ThemeLike): string | undefined {
	const usage = ctx.getContextUsage();
	if (!usage) return undefined;

	const model = ctx.model as { contextWindow?: number } | undefined;
	const contextWindow = model?.contextWindow;
	if (contextWindow && contextWindow > 0) {
		const percent = Math.min(999, Math.round((usage.tokens / contextWindow) * 100));
		const color = percent >= 85 ? "warning" : "dim";
		return theme.fg(color, `ctx:${percent}%`);
	}

	return theme.fg("dim", `ctx:${formatCount(usage.tokens)}`);
}

function formatTotals(ctx: ExtensionContext, theme: ThemeLike): string | undefined {
	let input = 0;
	let output = 0;
	let cost = 0;

	for (const entry of ctx.sessionManager.getBranch()) {
		if (!isAssistantEntry(entry)) continue;
		const usage = entry.message.usage;
		if (!usage) continue;
		input += usage.input ?? 0;
		output += usage.output ?? 0;
		cost += usage.cost?.total ?? 0;
	}

	if (input === 0 && output === 0 && cost === 0) return undefined;
	return theme.fg("dim", `↑${formatCount(input)} ↓${formatCount(output)} $${cost.toFixed(3)}`);
}

function formatExternalStatuses(
	footerData: { getExtensionStatuses: () => ReadonlyMap<string, string> },
	theme: ThemeLike,
): string | undefined {
	const statuses = Array.from(footerData.getExtensionStatuses())
		.filter(([key, value]) => key !== STATUS_LINE_ID && value.trim().length > 0)
		.map(([, value]) => value);

	if (statuses.length === 0) return undefined;
	return theme.fg("dim", statuses.join(" "));
}

function placeLeftRight(left: string, right: string, width: number): string {
	if (width <= 0) return "";
	if (!right) return truncateToWidth(left, width);

	const leftWidth = visibleWidth(left);
	const rightWidth = visibleWidth(right);
	const gap = width - leftWidth - rightWidth;

	if (gap >= 1) {
		return truncateToWidth(left + " ".repeat(gap) + right, width);
	}

	if (width < 24) return truncateToWidth(left, width);

	const rightBudget = Math.min(rightWidth, Math.max(10, Math.floor(width * 0.45)));
	const leftBudget = Math.max(1, width - rightBudget - 1);
	return `${truncateToWidth(left, leftBudget, "…")} ${truncateToWidth(right, rightBudget, "…")}`;
}

function formatCount(value: number): string {
	if (value < 1000) return `${value}`;
	if (value < 1_000_000) return `${(value / 1000).toFixed(value < 10_000 ? 1 : 0)}k`;
	return `${(value / 1_000_000).toFixed(1)}m`;
}

function formatDuration(ms: number): string {
	const seconds = Math.max(0, Math.round(ms / 1000));
	if (seconds < 60) return `${seconds}s`;
	const minutes = Math.floor(seconds / 60);
	const remainder = seconds % 60;
	return `${minutes}m${remainder.toString().padStart(2, "0")}s`;
}

function isAssistantEntry(entry: unknown): entry is { type: "message"; message: AssistantMessage } {
	return (
		typeof entry === "object" &&
		entry !== null &&
		(entry as { type?: unknown }).type === "message" &&
		typeof (entry as { message?: { role?: unknown } }).message === "object" &&
		(entry as { message: { role?: unknown } }).message.role === "assistant"
	);
}
