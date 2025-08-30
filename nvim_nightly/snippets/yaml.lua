---@diagnostic disable: undefined-global

return {
    s(
        { trig = "slb", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: placeholder
              labels:
                placeholder
              annotations:
                placeholder
            spec:
              selector:
                placeholder
              type: LoadBalancer
              ports:
                - protocol: TCP
                  port: placeholder
                  targetPort: placeholder
            ]],
            {}
        )
    ),
    s(
        { trig = "snp", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: placeholder
              labels:
                placeholder
              annotations:
                placeholder
            spec:
              selector:
                placeholder
              type: NodePort
              ports:
                - port: placeholder
                  targetPort: placeholder
                  nodePort: placeholder
            ]],
            {}
        )
    ),
    s(
        { trig = "sen", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: placeholder
              labels:
                placeholder
              annotations:
                placeholder
            spec:
              type: LoadBalancer
              externalName: placeholder
            ]],
            {}
        )
    ),
    s(
        { trig = "sci", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            apiVersion: v1
            kind: Service
            metadata:
              name: placeholder
              labels:
                placeholder
              annotations:
                placeholder
            spec:
              selector:
                placeholder
              ports:
                - protocol: TCP
                  port: placeholder
                  targetPort: placeholder
            ]],
            {}
        )
    ),
    s(
        { trig = "sts", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            apiVersion: apps/v1
            kind: StatefulSet
            metadata:
              name: placeholder
              labels:
                placeholder
              annotations:
                placeholder
            spec:
              # Must match .metadata.name of the headless service
              serviceName: placeholder
              replicas: placeholder
              # How long to wait before new pods considered available
              minReadySeconds: placeholder
              # Allow parallel start/termination (instead of OrderedReady)
              podManagementPolicy: Parallel
              persistentVolumeClaimRetentionPolicy:
                whenDeleted: Delete
                whenScaled: Retain
              updateStrategy:
                type: RollingUpdate
                rollingUpdate:
                  # Update only pods with index 1 or greater
                  partition: 0
                  maxUnavailable: 1
              selector:
                matchLabels:
                  # Must match pod template labels
                  placeholder
              # k8s 1.31+, control ordinal range (index of pods created)
              ordinals:
                # Default 0
                start: 0
              template:
                metadata:
                  labels:
                    placeholder
                spec:
                  imagePullSecrets:
                    - name: placeholder
                  affinity:
                    podAntiAffinity:
                      preferredDuringSchedulingIgnoredDuringExecution:
                          - weight: placeholder
                            podAffinityTerm:
                              labelSelector:
                                matchExpressions:
                                  - key: placeholder
                                    operator: placeholder
                                    values: ["placeholder"]
                              topologyKey: placeholder
                  nodeSelector:
                    disktype: ssd
                  tolerations:
                    - key: placeholder
                      operator: placeholder
                      value: placeholder
                      effect: placeholder
                  serviceAccountName: placeholder
                  terminationGracePeriodSeconds: placeholder
                  initContainers:
                    - name: placeholder
                      image: placeholder
                      imagePullPolicy: placeholder
                      command: placeholder
                      securityContext:
                        allowPrivilegeEscalation: false
                        runAsNonRoot: true
                        readOnlyRootFilesystem: true
                        runAsUser: 10001
                        runAsGroup: 10001
                        fsGroup: 10001
                        capabilities:
                          drop:
                            - "ALL"
                      resources:
                        requests:
                          cpu: placeholder
                          memory: placeholder
                        limits:
                          cpu: placeholder
                          memory: placeholder
                      env:
                        - name: placeholder
                          value: placeholder
                        - name: placeholder
                          valueFrom:
                            configMapKeyRef:
                              name: placeholder
                              key: placeholder
                        - name: placeholder
                          valueFrom:
                            secretKeyRef:
                              name: placeholder
                              key: placeholder
                        - name:
                          valueFrom:
                            fieldPath: placeholder
                        - name: CPU_REQUEST
                          valueFrom:
                            resourceFieldRef:
                              containerName: my-container
                              resource: requests.cpu
                      envFrom:
                        - configMapRef:
                            name: placeholder
                        - secretRef:
                            name: placeholder
                      volumeMounts:
                        - name: placeholder
                          mountPath: placeholder
                          subPath: placeholder
                  containers:
                    - name: placeholder
                      image: placeholder
                      imagePullPolicy: placeholder
                      command: placeholder
                      ports:
                        - containerPort: placeholder
                          name: placeholder
                      securityContext:
                        allowPrivilegeEscalation: false
                        runAsNonRoot: true
                        readOnlyRootFilesystem: true
                        runAsUser: 10001
                        runAsGroup: 10001
                        fsGroup: 10001
                        capabilities:
                          drop:
                            - "ALL"
                      resources:
                        requests:
                          cpu: placeholder
                          memory: placeholder
                        limits:
                          cpu: placeholder
                          memory: placeholder
                      env:
                        - name: placeholder
                          value: placeholder
                        - name:
                          valueFrom:
                            configMapKeyRef:
                              name: placeholder
                              key: placeholder
                        - name:
                          valueFrom:
                            secretKeyRef:
                              name: placeholder
                              key: placeholder
                        - name:
                          valueFrom:
                            fieldPath: placeholder
                        - name: CPU_REQUEST
                          valueFrom:
                            resourceFieldRef:
                              containerName: my-container
                              resource: requests.cpu
                      envFrom:
                        - configMapRef:
                            name: placeholder
                        - secretRef:
                            name: placeholder
                      volumeMounts:
                        - name: placeholder
                          mountPath: placeholder
                          subPath: placeholder
                      startupProbe:
                        # You need to choose one of the varians below
                        exec:
                          command:
                            - cat
                            - /tmp/healthy
                        tcpSocket:
                          port: placeholder
                        grpc:
                          port: placeholder
                        httpGet:
                          scheme placeholder:
                          path: placeholder
                          port: placeholder
                          httpHeaders:
                            - name: placeholder
                              value: placeholder
                        initialDelaySeconds: placeholder
                        periodSeconds: placeholder
                        timeoutSecons: placeholder
                        successThreshold: placeholder
                        failureThreshold: placeholder
                      readinessProbe:
                        # You need to choose one of the varians below
                        exec:
                          command:
                            - cat
                            - /tmp/healthy
                        tcpSocket:
                          port: placeholder
                        grpc:
                          port: placeholder
                        httpGet:
                          scheme: placeholder
                          path: placeholder
                          port: placeholder
                          httpHeaders:
                            - name: placeholder
                              value: placeholder
                        initialDelaySeconds: placeholder
                        periodSeconds: placeholder
                        timeoutSecons: placeholder
                        successThreshold: placeholder
                        failureThreshold: placeholder
                      livenessProbe:
                        # You need to choose one of the varians below
                        exec:
                          command:
                            - cat
                            - /tmp/healthy
                        tcpSocket:
                          port: placeholder
                        grpc:
                          port: placeholder
                        httpGet:
                          scheme: placeholder
                          path: placeholder
                          port: placeholder
                          httpHeaders:
                            - name: placeholder
                              value: placeholder
                        initialDelaySeconds: placeholder
                        periodSeconds: placeholder
                        timeoutSecons: placeholder
                        successThreshold: placeholder
                        failureThreshold: placeholder
                  volumes:
                    - name: placeholder
                      configMap:
                        name: placeholder
                    - name: placeholder
                      secret:
                        secretName: placeholder
            volumeClaimTemplates:
              - metadata:
                  name: placeholder
                spec:
                  accessModes: ["ReadWriteOnce"]
                  storageClassName: placeholder
                  resources:
                    requests:
                      storage: placeholder
            ]],
            {}
        )
    ),
    s(
        { trig = "dpl", snippetType = "autosnippet" },
        fmta(
            [[
            ---
            ]],
            {}
        )
    ),
}
