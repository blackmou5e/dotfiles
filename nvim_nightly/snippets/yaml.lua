---@diagnostic disable: undefined-global

return {
    s(
        { trig = "slb", snippetType = "autosnippet" },
        fmta(
            [[
            apiVersion: v1
            kind: Service
            metadata:
              name: <>
              labels:
                <>
            spec:
              selector:
                <>
              type: LoadBalancer
              ports:
                - protocol: TCP
                  port: <>
                  targetPort: <>
            ]],
            { i(1), i(2), i(3), i(4), i(5) }
        )
    ),
    s(
        { trig = "snp", snippetType = "autosnippet" },
        fmta(
            [[
            apiVersion: v1
            kind: Service
            metadata:
              name: <>
              labels:
                <>
            spec:
              selector:
                <>
              type: NodePort
              ports:
                - port: <>
                  targetPort: <>
                  nodePort: <>
            ]],
            { i(1), i(2), i(3), i(4), i(5), i(6) }
        )
    ),
    s(
        { trig = "sem", snippetType = "autosnippet" },
        fmta(
            [[
            apiVersion: v1
            kind: Service
            metadata:
              name: <>
              labels:
                <>
            spec:
              type: LoadBalancer
              externalName: <>
            ]],
            { i(1), i(2), i(3) }
        )
    ),
}
