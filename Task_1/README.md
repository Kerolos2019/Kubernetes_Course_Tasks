# Task 1 — Multi-container Pods (Init Container & Sidecar)

An nginx "hello" page that shows the current time, refreshed every 5 seconds by a sidecar,
with an init container that gates startup. No volumes: the sidecar writes into the nginx
container's filesystem through the shared process namespace (`/proc/<nginx-pid>/root`).

```text
hello in MLOPS MENA COMMUNITY : 2026-11-06 18:42:10
```

## Environment

The course suggests minikube; I used a **KubeLabs** kubeadm cluster with the same shape
(1 control plane + 2 workers, Kubernetes v1.37, containerd + flannel).

| Course (minikube) | Mine (KubeLabs) |
|---|---|
| `minikube` (control plane) | `cplane-01` |
| `minikube-m02` (worker) | `node-01` |
| `minikube-m03` (worker) | `node-02` |

`kubectl` runs from the KubeLabs `dev-machine`, where the kubeconfig is provisioned.

## Files

| File | Purpose |
|---|---|
| `namespace.yaml` | Namespace `webapp` |
| `deployment.yaml` | Deployment `web-deployment`: 3 replicas, `init-done` + `nginx` + `time-updater` |

## Pod design

| Container | Type | Image | Job |
|---|---|---|---|
| `init-done` | init | `busybox:1.36` | `echo done`, exit 0. Nothing else starts until it succeeds. |
| `nginx` | main | `nginx:1.27` | Writes `index.html` with the time, then `exec nginx -g 'daemon off;'` on port 80 |
| `time-updater` | sidecar | `busybox:1.36` | Every 5 s: finds nginx with `pgrep -o nginx`, rewrites `/proc/$PID/root/usr/share/nginx/html/index.html`. Needs `SYS_PTRACE`. |

## Steps

```bash
kubectl get nodes
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl get pods -n webapp -o wide -w
kubectl port-forward -n webapp deploy/web-deployment 8080:80   # terminal 2
curl -s localhost:8080; sleep 5; curl -s localhost:8080        # terminal 3
```

![nodes](screenshots/01-nodes.png)
![pods running](screenshots/02-pods-running.png)
![time updates](screenshots/03-time-updates.png)

## Verification

| # | Check | Result |
|---|---|---|
| 1 | 3 nodes Ready | ✅ |
| 2 | Deployment READY 3/3 | ✅ |
| 3 | 3 Pods `2/2 Running` | ✅ |
| 4 | Containers `init-done nginx time-updater` | ✅ |
| 5 | init logs `done` | ✅ |
| 6 | sidecar `ps` shows `nginx: master process` | ✅ |
| 7 | `index.html` time changes after 5 s | ✅ |
| 8 | `.spec.template.spec.volumes` empty | ✅ |

![verification](screenshots/04-verify.png)

## Breaking the init container

Changed only the init command to `["sh", "-c", "echo 'init failed'; exit 1"]` and re-applied.

![failure](screenshots/05-init-crashloop.png)
![describe](screenshots/06-describe-exit1.png)

**Which status does the new Pod show?** `Init:Error`, then `Init:CrashLoopBackOff`, READY `0/2`.
Kubernetes restarts the failing init container with a growing delay (10 s, 20 s, 40 s … up to 5 min).

**Do `nginx` and `time-updater` start?** No. Regular containers start only after every
init container exits with code 0. `kubectl describe` shows them as `Waiting / PodInitializing`.

**Is the page still reachable, and why?** Yes. The change triggers a rolling update. With the
default strategy (`maxSurge: 25%`, `maxUnavailable: 25%` → for 3 replicas: 1 extra Pod, 0 Pods
removed), Kubernetes creates **one** new Pod and keeps the 3 old ones until the new one is Ready.
It never becomes Ready, so the old Pods are never removed: zero downtime. The rollout simply stalls.

## Fix

Restored `command: ["sh", "-c", "echo done"]` and re-applied. The Deployment goes back to the
working Pod template, deletes the stuck Pod, and is `3/3` again.

![fixed](screenshots/07-fixed.png)
