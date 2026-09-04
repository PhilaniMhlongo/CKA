#!/usr/bin/env python3
"""
enrich-cka-solutions-docx.py - improve the KodeKloud "Ultimate CKA" solutions .docx

Takes the original document and produces an enriched copy. Everything it does is
mechanical and reproducible, so the source document never needs to live in this
repository:

  Structure
    - promotes every "Question N:" to Heading 2 (the original has none)
    - inserts an auto-building table of contents
    - sets command lines in a monospace face with light shading

  Corrections (see docs/ultimate-cka-solutions-review.md for why)
    - service/pod DNS FQDNs, grep -E, /etc/kubernetes case, k top, and the
      scheduler-vs-controller-manager attribution

  Additions
    - front matter: how the mock exam is structured; how this document's own
      question mix compares to the real domain weighting; a question index
    - Appendix A: solutions for the questions the document leaves unanswered
    - Appendix B: the topics the document never covers, with working commands
    - Appendix C: the corrections applied

Usage:
    python3 scripts/enrich-cka-solutions-docx.py INPUT.docx OUTPUT.docx
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from xml.etree import ElementTree as ET

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
XML_SPACE = '{http://www.w3.org/XML/1998/namespace}space'
USABLE_WIDTH = 9026  # twips: A4 minus the document's 1440 twip margins


def q(name):
    return f'{{{W}}}{name}'


# child orders are schema-enforced; we only list the elements we touch
PPR_ORDER = [
    'pStyle', 'keepNext', 'keepLines', 'pageBreakBefore', 'framePr', 'widowControl',
    'numPr', 'suppressLineNumbers', 'pBdr', 'shd', 'tabs', 'suppressAutoHyphens',
    'kinsoku', 'wordWrap', 'overflowPunct', 'topLinePunct', 'autoSpaceDE', 'autoSpaceDN',
    'bidi', 'adjustRightInd', 'snapToGrid', 'spacing', 'ind', 'contextualSpacing',
    'mirrorIndents', 'suppressOverlap', 'jc', 'textDirection', 'textAlignment',
    'textboxTightWrap', 'outlineLvl', 'divId', 'cnfStyle', 'rPr', 'sectPr',
]
RPR_ORDER = [
    'rStyle', 'rFonts', 'b', 'bCs', 'i', 'iCs', 'caps', 'smallCaps', 'strike', 'dstrike',
    'outline', 'shadow', 'emboss', 'imprint', 'noProof', 'snapToGrid', 'vanish',
    'webHidden', 'color', 'spacing', 'w', 'kern', 'position', 'sz', 'szCs', 'highlight',
    'u', 'effect', 'bdr', 'shd', 'fitText', 'vertAlign', 'rtl', 'cs',
]


def ordered_set(parent, name, order, **attrs):
    """Insert or update a child element, keeping the schema's required order."""
    el = parent.find(q(name))
    if el is None:
        el = ET.Element(q(name))
        idx = order.index(name)
        pos = len(list(parent))
        for i, child in enumerate(parent):
            nm = child.tag.split('}')[1]
            if nm in order and order.index(nm) > idx:
                pos = i
                break
        parent.insert(pos, el)
    for k, v in attrs.items():
        el.set(q(k), v)
    return el


def get_ppr(p):
    pPr = p.find(q('pPr'))
    if pPr is None:
        pPr = ET.Element(q('pPr'))
        p.insert(0, pPr)
    return pPr


# ---------------------------------------------------------------- block builders

def para(text='', style=None, bold=False, mono=False, shaded=False, indent=None):
    p = ET.Element(q('p'))
    if style or shaded or indent:
        pPr = get_ppr(p)
        if style:
            ordered_set(pPr, 'pStyle', PPR_ORDER, val=style)
        if shaded:
            ordered_set(pPr, 'shd', PPR_ORDER, val='clear', color='auto', fill='F3F4F6')
            ordered_set(pPr, 'spacing', PPR_ORDER, before='20', after='20')
        if indent:
            ordered_set(pPr, 'ind', PPR_ORDER, left=str(indent))
    r = ET.SubElement(p, q('r'))
    rPr = ET.SubElement(r, q('rPr'))
    if mono:
        ordered_set(rPr, 'rFonts', RPR_ORDER, ascii='Consolas', hAnsi='Consolas', cs='Consolas')
        ordered_set(rPr, 'sz', RPR_ORDER, val='18')
        ordered_set(rPr, 'szCs', RPR_ORDER, val='18')
    if bold:
        ordered_set(rPr, 'b', RPR_ORDER)
    t = ET.SubElement(r, q('t'))
    t.text = text
    t.set(XML_SPACE, 'preserve')
    return p


def code_block(text):
    """One shaded monospace paragraph per line, so blocks read as a unit."""
    return [para(line, mono=True, shaded=True, indent=227) for line in text.split('\n')]


def page_break():
    p = ET.Element(q('p'))
    r = ET.SubElement(p, q('r'))
    br = ET.SubElement(r, q('br'))
    br.set(q('type'), 'page')
    return p


def table(rows, widths, header=True):
    """rows: list of lists of strings. widths: twips, must sum to USABLE_WIDTH."""
    tbl = ET.Element(q('tbl'))
    tblPr = ET.SubElement(tbl, q('tblPr'))
    ET.SubElement(tblPr, q('tblStyle')).set(q('val'), 'TableGrid')
    tblW = ET.SubElement(tblPr, q('tblW'))
    tblW.set(q('w'), str(sum(widths)))
    tblW.set(q('type'), 'dxa')
    borders = ET.SubElement(tblPr, q('tblBorders'))
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        b = ET.SubElement(borders, q(edge))
        b.set(q('val'), 'single')
        b.set(q('sz'), '4')
        b.set(q('color'), 'BFBFBF')
    grid = ET.SubElement(tbl, q('tblGrid'))
    for wdt in widths:
        ET.SubElement(grid, q('gridCol')).set(q('w'), str(wdt))

    for ri, row in enumerate(rows):
        tr = ET.SubElement(tbl, q('tr'))
        for ci, cell in enumerate(row):
            tc = ET.SubElement(tr, q('tc'))
            tcPr = ET.SubElement(tc, q('tcPr'))
            tcW = ET.SubElement(tcPr, q('tcW'))
            tcW.set(q('w'), str(widths[ci]))
            tcW.set(q('type'), 'dxa')
            if header and ri == 0:
                shd = ET.SubElement(tcPr, q('shd'))
                shd.set(q('val'), 'clear')
                shd.set(q('color'), 'auto')
                shd.set(q('fill'), 'E8EDF3')
            tc.append(para(cell, bold=(header and ri == 0)))
    return tbl


def toc_block():
    """Heading plus a TOC field marked dirty so Word builds it on open."""
    out = [para('Contents', style='Heading1')]
    p = ET.Element(q('p'))
    for kind, payload in (('begin', None), ('instr', ' TOC \\o "1-2" \\h \\z \\u '),
                          ('separate', None), ('text', 'Press Ctrl+A then F9 to build the table of contents.'),
                          ('end', None)):
        r = ET.SubElement(p, q('r'))
        if kind == 'instr':
            it = ET.SubElement(r, q('instrText'))
            it.set(XML_SPACE, 'preserve')
            it.text = payload
        elif kind == 'text':
            t = ET.SubElement(r, q('t'))
            t.text = payload
        else:
            fc = ET.SubElement(r, q('fldChar'))
            fc.set(q('fldCharType'), kind)
            if kind == 'begin':
                fc.set(q('dirty'), 'true')
    out.append(p)
    out.append(page_break())
    return out


# ---------------------------------------------------------------- classification

CMD = (r'^\s*(kubectl|k|helm|etcdctl|systemctl|journalctl|crictl|openssl|apt|apt-get|'
       r'curl|vim|vi|cat|echo|ssh|sudo|docker|kubeadm|export|chmod|mkdir|cp|mv|rm|grep|'
       r'awk|sed|wget|nano|touch|ls|cd|tar|scp|nc|dig|nslookup|ps|top|df)\b')
HOST = r'^(student-node|controlplane|node0[0-9]|cluster[0-9]|master|worker)'
TBL = r'^(NAME|NAMESPACE|POD|READY|STATUS|TYPE|CLASS|CAPACITY|DATA|KIND|VERSION|CURRENT|USER)\b.*\s{2,}'
YAML = (r'^\s*(apiVersion|kind|metadata|spec|status|containers|volumes|rules|subjects|'
        r'roleRef|data|selector|template|ports|image|name|namespace|labels|annotations):')
RESULT = r'(created|configured|deleted|unchanged|replaced|approved)\s*$'


def is_code(s):
    s = s.rstrip()
    if not s.strip():
        return False
    if '➜' in s or '$ ' in s[:8]:
        return True
    if re.search(HOST, s) or re.match(CMD, s) or re.match(TBL, s) or re.match(YAML, s):
        return True
    if re.search(RESULT, s) and len(s) < 90:
        return True
    if re.search(r'\s{2,}\S+\s{2,}', s) and not s.rstrip().endswith('.'):
        return True
    return False


CORRECTIONS = [
    (lambda s: '/etc/Kubernetes/' in s,
     lambda s: s.replace('/etc/Kubernetes/', '/etc/kubernetes/'),
     'path case: /etc/Kubernetes -> /etc/kubernetes'),
    (lambda s: re.match(r'^\s*K top\b', s),
     lambda s: re.sub(r'^(\s*)K top', r'\1k top', s),
     'command case: K top -> k top'),
    (lambda s: 'Kubectl logs logger-cka03-arch' in s,
     lambda s: "kubectl logs logger-cka03-arch | grep -E 'INFO|ERROR' > /root/logger-cka03-arch-all",
     'grep -E, lowercase kubectl, straight quotes'),
    (lambda s: 'nslookup <service-name>.<namespace>.cluster.local' in s,
     lambda s: s.replace('<service-name>.<namespace>.cluster.local',
                         '<service-name>.<namespace>.svc.cluster.local'),
     'service FQDN: added missing .svc'),
    (lambda s: 'nslookup <pod_name>.local' in s,
     lambda s: s.replace('<pod_name>.local', '<pod-ip-with-dashes>.<namespace>.pod.cluster.local'),
     'pod DNS record corrected'),
    (lambda s: 'responsibility of the Kubernetes controller manager' in s,
     lambda s: ('Creating the Pods behind a Deployment is the responsibility of the '
                'kube-controller-manager (the kube-scheduler only assigns already-created Pods '
                'to nodes), so let us check the status of the static pods in the kube-system '
                'namespace first to see if it is up and running.'),
     'concept: scheduling vs pod creation'),
]


def set_text(p, new):
    runs = [r for r in p.iter(q('r')) if r.find(q('t')) is not None]
    if not runs:
        return False
    t = runs[0].find(q('t'))
    t.text = new
    t.set(XML_SPACE, 'preserve')
    for r in runs[1:]:
        for tt in r.findall(q('t')):
            r.remove(tt)
    return True


# ---------------------------------------------------------------- content

def front_matter(index_rows, section_rows, cluster_rows):
    b = [para('How this mock exam is structured', style='Heading1')]
    b += [para(
        'This section was added to the document. It summarises the exam environment '
        'described on the course page, because the original text goes straight into the '
        'questions without describing the environment they run in.')]
    b += [para('The paper', style='Heading2')]
    b += [para(
        '20 questions are generated at random from a large pool, and you get 2 hours. The '
        'knowledge area and the weight of each question are shown above it, so you can see '
        'what a question is worth before deciding whether to attempt it now or flag it. At '
        'the end the lab is auto-validated and you are given a score.')]
    b += [para(
        'Questions are randomised per attempt, so two sittings are very unlikely to be '
        'identical. That is a strength for practice and a trap for revision: a high score on '
        'one attempt does not mean you have seen the pool.')]
    b += [para('The five knowledge areas', style='Heading2')]
    b += [table([['Knowledge area', 'Weight', 'What it usually looks like'],
                 ['Troubleshooting', '30%', 'A broken deployment, service, node or control-plane component'],
                 ['Architecture, Installation, Maintenance', '25%', 'RBAC, etcd, secrets, cluster and node administration'],
                 ['Services and Networking', '20%', 'Services, endpoints, Ingress, DNS, NetworkPolicy'],
                 ['Workloads and Scheduling', '15%', 'Deployments, rollouts, resources, taints and affinity'],
                 ['Storage', '10%', 'PV, PVC, StorageClass, volume mounts']],
                [3000, 900, 5126])]
    b += [para('The four clusters', style='Heading2')]
    b += [para(
        'You are logged in to the student-node. From there you can reach every cluster and '
        'SSH to their nodes. Some clusters are dedicated to particular knowledge areas, so '
        'the context you are told to switch to is a hint about the kind of question you are '
        'being asked.')]
    b += code_block(
        'kubectl config get-contexts          # what is available\n'
        'kubectl config use-context cluster1  # ALWAYS run this first, per question\n'
        'kubectl config current-context       # confirm before you touch anything\n'
        'ssh cluster1-controlplane            # node-level work happens here')
    b += [para(
        'Running a correct answer against the wrong cluster scores zero. Make the context '
        'command the first thing you do for every question, not something you assume carried '
        'over from the last one.', bold=True)]

    b += [page_break(), para('This document versus the real weighting', style='Heading1')]
    b += [para(
        'The course randomises questions and respects the official weighting across a whole '
        'attempt. This document is one person\'s set of attempts, so its own mix has drifted '
        'from the target. Worth knowing before you use it as a syllabus.')]
    b += [table(section_rows, [3400, 1200, 1200, 3226])]
    b += [para(
        'Service Networking is the gap that matters: it is 20% of the exam and about 13% of '
        'this document. Practise it elsewhere to compensate.', bold=True)]
    b += [para('Cluster coverage', style='Heading2')]
    b += [para(
        'The questions collected here are also unevenly spread across the four clusters, '
        'which matters because clusters are dedicated to knowledge areas.')]
    b += [table(cluster_rows, [2200, 1600, 5226])]

    b += [page_break(), para('Question index', style='Heading1')]
    b += [para(
        'Added for navigation: every question in the document, the cluster it runs on, and '
        'what it asks. Use it to find a topic rather than scrolling.')]
    b += [table(index_rows, [900, 2100, 1000, 5026])]
    b += [page_break()]
    return b


APPENDIX_A = [
    ('h1', 'Appendix A - solutions for the unanswered questions'),
    ('p', 'The original document states these tasks and stops. Two of them repeat questions '
          'that are answered earlier, so they are cross-referenced rather than repeated. '
          'These solutions were written for this copy and are not KodeKloud material.'),

    ('h2', 'Practical Exercise - ocean-tv-wl09 (Scheduling, cluster1)'),
    ('p', 'Deployment with kodekloud/webapp-color:v1, 3 replicas, maxUnavailable 40% and '
          'maxSurge 55%; then upgrade to v2, record the revision count, and roll back.'),
    ('code', 'kubectl config use-context cluster1\n'
             '\n'
             '# maxSurge/maxUnavailable have no imperative flag - generate then edit\n'
             'kubectl create deployment ocean-tv-wl09 --image=kodekloud/webapp-color:v1 \\\n'
             '  --replicas=3 --dry-run=client -o yaml > ocean.yaml'),
    ('p', 'Add the strategy block under spec: (a sibling of replicas and selector):'),
    ('code', 'spec:\n'
             '  strategy:\n'
             '    type: RollingUpdate\n'
             '    rollingUpdate:\n'
             '      maxUnavailable: 40%\n'
             '      maxSurge: 55%'),
    ('code', 'kubectl apply -f ocean.yaml\n'
             'kubectl rollout status deployment/ocean-tv-wl09\n'
             '\n'
             '# upgrade and watch it out\n'
             'kubectl set image deployment/ocean-tv-wl09 webapp-color=kodekloud/webapp-color:v2\n'
             'kubectl rollout status deployment/ocean-tv-wl09\n'
             '\n'
             '# the question asks for the revision COUNT, not the revision list\n'
             'kubectl rollout history deployment/ocean-tv-wl09\n'
             'kubectl rollout history deployment/ocean-tv-wl09 --no-headers | wc -l > /opt/revision-count.txt\n'
             '\n'
             'kubectl rollout undo deployment/ocean-tv-wl09\n'
             'kubectl rollout status deployment/ocean-tv-wl09'),
    ('p', 'Two traps. The container name comes from the image, so confirm it with '
          '"kubectl get deploy ocean-tv-wl09 -o jsonpath=\'{.spec.template.spec.containers[0].name}\'" '
          'before using set image. And percentages must be quoted strings in YAML if you '
          'write them by hand.'),

    ('h2', 'Practical Exercise - messaging-cka07-svcn (Service Networking, cluster3)'),
    ('p', 'A redis:alpine pod labelled tier=msg, exposed inside the cluster on port 6379.'),
    ('code', 'kubectl config use-context cluster3\n'
             '\n'
             'kubectl run messaging-cka07-svcn --image=redis:alpine --labels=tier=msg\n'
             'kubectl expose pod messaging-cka07-svcn --name=messaging-service-cka07-svcn \\\n'
             '  --port=6379 --target-port=6379 --type=ClusterIP\n'
             '\n'
             '# the only check that matters: does the service actually select the pod?\n'
             'kubectl get endpoints messaging-service-cka07-svcn'),
    ('p', 'kubectl expose copies the pod\'s labels into the selector, which is why the labels '
          'must be set when the pod is created. If you add them afterwards the service is '
          'created with the wrong selector and the endpoint list stays empty.'),

    ('h2', 'Practical Exercise - peach-pvc-cka05-str (Storage, cluster1)'),
    ('p', 'Add a PVC claiming 100Mi from the existing peach-pv-cka05-str, then mount it in '
          'the pod defined at /root/peach-pod-cka05-str.yaml at /var/www/html.'),
    ('code', 'kubectl config use-context cluster1\n'
             '\n'
             '# read the PV FIRST - the PVC must match it or it will never bind\n'
             'kubectl get pv peach-pv-cka05-str -o yaml | grep -E "storageClassName|accessModes|storage:"'),
    ('p', 'Then add the claim and the mount to the manifest:'),
    ('code', 'apiVersion: v1\n'
             'kind: PersistentVolumeClaim\n'
             'metadata:\n'
             '  name: peach-pvc-cka05-str\n'
             'spec:\n'
             '  accessModes: ["ReadWriteOnce"]\n'
             '  storageClassName: <copy from the PV>\n'
             '  resources:\n'
             '    requests:\n'
             '      storage: 100Mi\n'
             '---\n'
             '# in the pod spec:\n'
             '  volumes:\n'
             '  - name: peach-vol\n'
             '    persistentVolumeClaim:\n'
             '      claimName: peach-pvc-cka05-str\n'
             '  containers:\n'
             '  - volumeMounts:\n'
             '    - name: peach-vol\n'
             '      mountPath: /var/www/html'),
    ('code', 'kubectl apply -f /root/peach-pod-cka05-str.yaml\n'
             'kubectl get pvc peach-pvc-cka05-str      # must read Bound\n'
             'kubectl get pod peach-pod-cka05-str      # must read Running'),
    ('p', 'The grader checks Bound and Running, so both are worth confirming. A PVC that stays '
          'Pending is nearly always a storageClassName or accessModes mismatch against the PV.'),

    ('h2', 'Practical Exercise - hr-web-app-cka08-svcn (Service Networking, cluster3)'),
    ('p', 'Deployment of kodekloud/webapp-color with 2 replicas, exposed on node port 30082 '
          'while the app listens on 8080.'),
    ('code', 'kubectl config use-context cluster3\n'
             '\n'
             'kubectl create deployment hr-web-app-cka08-svcn \\\n'
             '  --image=kodekloud/webapp-color --replicas=2\n'
             '\n'
             '# expose gives you a NodePort but assigns a RANDOM port, so patch it\n'
             'kubectl expose deployment hr-web-app-cka08-svcn \\\n'
             '  --name=hr-web-app-service-cka08-svcn \\\n'
             '  --type=NodePort --port=8080 --target-port=8080\n'
             '\n'
             'kubectl patch service hr-web-app-service-cka08-svcn \\\n'
             '  -p \'{"spec":{"ports":[{"port":8080,"targetPort":8080,"nodePort":30082}]}}\'\n'
             '\n'
             'kubectl get svc hr-web-app-service-cka08-svcn\n'
             'kubectl get endpoints hr-web-app-service-cka08-svcn   # expect 2 addresses'),
    ('p', 'You cannot ask kubectl expose for a specific nodePort, which is why this is a two '
          'step task. The grader checks for 2 endpoints, so wait for both pods to be Ready.'),

    ('h2', 'green-deployment-cka15-trb (Troubleshooting, cluster1)'),
    ('p', 'The document ends here with no solution, and the specific fault is not recorded '
          'anywhere in it. Rather than invent a fix, here is the procedure that finds this '
          'class of fault - a pod that starts, crashes and restarts repeatedly.'),
    ('code', 'kubectl config use-context cluster1\n'
             '\n'
             'kubectl get pods -l app=green-deployment-cka15-trb\n'
             'kubectl describe pod <pod> | tail -25          # events sit at the bottom\n'
             'kubectl logs <pod> --previous                  # the CRASHED instance, not the new one\n'
             'kubectl get deploy green-deployment-cka15-trb -o yaml | head -60'),
    ('p', 'Read the STATUS column first, because it names the fault class:'),
    ('code', 'CrashLoopBackOff            -> container starts then exits: check logs --previous\n'
             '                               (bad command/args, missing env var, or a liveness\n'
             '                               probe killing a healthy but slow app)\n'
             'CreateContainerConfigError  -> a referenced ConfigMap or Secret does not exist\n'
             'ImagePullBackOff            -> wrong image name, tag or registry\n'
             'Running but 0/1 READY       -> readiness probe failing: check path, port, delay\n'
             'OOMKilled (in describe)     -> memory limit too low'),
    ('p', 'For a pod that restarts repeatedly but whose logs look healthy, suspect the liveness '
          'probe before the application: an initialDelaySeconds shorter than the app\'s startup '
          'time produces exactly this symptom.'),

    ('h2', 'Cross-references'),
    ('p', 'Practical Exercise "frontend-wl04" repeats Scheduling Question 5, and "app-wl03" '
          'repeats Scheduling Question 3. Both are answered in those sections.'),
]


APPENDIX_B = [
    ('h1', 'Appendix B - topics this document does not cover'),
    ('p', 'Measured against a 46-topic CKA syllabus, this document covers 21 of them. The '
          'rest are below, with the minimum you need for each. Written for this copy; not '
          'KodeKloud material. Everything here is examinable and none of it appears in the '
          'questions above.'),

    ('h2', 'etcd restore'),
    ('p', 'The document covers taking a snapshot but not restoring one, which is the harder '
          'half and the half that gets asked. Restore into a NEW directory and repoint the '
          'static pod; never restore over the live data directory.'),
    ('code', 'etcdctl snapshot restore /opt/backup.db --data-dir=/var/lib/etcd-restore\n'
             '\n'
             'vim /etc/kubernetes/manifests/etcd.yaml\n'
             '#   volumes:\n'
             '#     - name: etcd-data\n'
             '#       hostPath:\n'
             '#         path: /var/lib/etcd-restore     <- was /var/lib/etcd\n'
             '\n'
             '# kubelet restarts etcd on manifest change; kubectl is down for 30-90s\n'
             'crictl ps | grep etcd'),

    ('h2', 'kubeadm cluster upgrade'),
    ('p', 'Order is the whole question, and the last step is the one people forget.'),
    ('code', 'kubeadm upgrade plan                     # 0. what can we go to? next PATCH only\n'
             'apt-mark unhold kubeadm && apt-get install -y kubeadm=1.32.2-1.1\n'
             'apt-mark hold kubeadm                    # 1. kubeadm binary FIRST\n'
             'kubeadm upgrade apply v1.32.2 -y         # 2. control plane (workers: upgrade node)\n'
             'kubectl drain <node> --ignore-daemonsets # 3. drain BEFORE the kubelet\n'
             'apt-mark unhold kubelet kubectl && apt-get install -y kubelet=1.32.2-1.1 kubectl=1.32.2-1.1\n'
             'apt-mark hold kubelet kubectl\n'
             'systemctl daemon-reload && systemctl restart kubelet\n'
             'kubectl uncordon <node>                  # 4. THE STEP THAT LOSES MARKS'),

    ('h2', 'Certificates'),
    ('code', 'kubeadm certs check-expiration > /tmp/before.txt\n'
             'kubeadm certs renew apiserver            # renew ONE cert if asked for one\n'
             'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates'),

    ('h2', 'Onboarding a user: CSR to kubeconfig'),
    ('p', 'CN becomes the username, O becomes the group. Kubernetes has no User object.'),
    ('code', 'openssl genrsa -out dev.key 2048\n'
             'openssl req -new -key dev.key -subj "/CN=dev-user/O=dev-team" -out dev.csr\n'
             '\n'
             'cat <<EOF | kubectl apply -f -\n'
             'apiVersion: certificates.k8s.io/v1\n'
             'kind: CertificateSigningRequest\n'
             'metadata: { name: dev-user }\n'
             'spec:\n'
             '  request: $(base64 -w0 < dev.csr)      # -w0 matters: no line wrapping\n'
             '  signerName: kubernetes.io/kube-apiserver-client\n'
             '  usages: ["client auth"]\n'
             'EOF\n'
             '\n'
             'kubectl certificate approve dev-user\n'
             'kubectl get csr dev-user -o jsonpath=\'{.status.certificate}\' | base64 -d > dev.crt\n'
             'kubectl create rolebinding dev-edit --clusterrole=edit --user=dev-user -n dev-ns\n'
             '\n'
             'kubectl config set-credentials dev-user --kubeconfig=dev.kubeconfig \\\n'
             '  --client-certificate=dev.crt --client-key=dev.key --embed-certs=true'),

    ('h2', 'Static pods'),
    ('p', 'Owned by the kubelet, not the API server. kubectl delete on the mirror pod does '
          'nothing lasting - only removing the file deletes it.'),
    ('code', 'grep staticPodPath /var/lib/kubelet/config.yaml   # /etc/kubernetes/manifests\n'
             '# write the manifest there; the mirror pod appears as <name>-<nodename>'),

    ('h2', 'Kubelet configuration'),
    ('code', 'vim /var/lib/kubelet/config.yaml         # maxPods, evictionHard, staticPodPath\n'
             'systemctl restart kubelet\n'
             'kubectl get node <node> -o jsonpath=\'{.status.capacity.pods}\''),

    ('h2', 'A node that is NotReady'),
    ('p', 'The kubelet is a systemd service, not a pod, so kubectl cannot fix it.'),
    ('code', 'systemctl status kubelet --no-pager\n'
             'journalctl -u kubelet -n 50 --no-pager   # the single most useful command here\n'
             'kubeadm init phase kubeconfig kubelet    # if kubelet.conf is missing/broken'),

    ('h2', 'Helm'),
    ('code', 'helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update\n'
             'helm search repo bitnami/nginx --versions\n'
             'helm show values <chart> | grep -i <thing>   # FIND the value, do not guess a flag\n'
             'helm install web bitnami/nginx -n ns --create-namespace --set replicaCount=2\n'
             'helm upgrade web bitnami/nginx -n ns --set replicaCount=3\n'
             'helm history web -n ns\n'
             'helm rollback web 1 -n ns                    # rolling back CREATES a new revision\n'
             'helm template web <chart> -n ns > out.yaml   # render without installing'),

    ('h2', 'Kustomize'),
    ('code', '# overlays/production/kustomization.yaml\n'
             'resources: [ ../../base ]\n'
             'namespace: prod\n'
             'namePrefix: prod-                 # deployment api becomes prod-api\n'
             'replicas:\n'
             '  - { name: api, count: 3 }       # target uses the ORIGINAL name\n'
             'configMapGenerator:\n'
             '  - name: web-content\n'
             '    files: [ index.html ]         # generated names get a content hash\n'
             '\n'
             'kubectl kustomize overlays/production/   # preview before applying\n'
             'kubectl apply -k overlays/production/'),

    ('h2', 'Gateway API'),
    ('p', 'Splits Ingress into infrastructure (Gateway: listeners, ports, TLS) and application '
          '(HTTPRoute: hostnames, paths, backends).'),
    ('code', 'kubectl get gatewayclass                 # find the class name first\n'
             '\n'
             'kind: Gateway                            # gateway.networking.k8s.io/v1\n'
             'spec:\n'
             '  gatewayClassName: nginx\n'
             '  listeners:\n'
             '  - { name: http, protocol: HTTP, port: 80 }\n'
             '---\n'
             'kind: HTTPRoute\n'
             'spec:\n'
             '  parentRefs: [ { name: main-gateway } ]\n'
             '  rules:\n'
             '  - matches: [ { path: { type: PathPrefix, value: /app1 } } ]\n'
             '    backendRefs: [ { name: app1-svc, port: 8080 } ]'),

    ('h2', 'HorizontalPodAutoscaler'),
    ('p', 'Utilisation is a percentage OF THE REQUEST. With no CPU request the HPA reads '
          '<unknown> and never scales, so setting requests is part of the answer.'),
    ('code', 'kubectl autoscale deployment web --cpu-percent=50 --min=1 --max=4\n'
             '\n'
             '# YAML needed the moment "behavior" is mentioned - use autoscaling/v2\n'
             'behavior:\n'
             '  scaleDown: { stabilizationWindowSeconds: 30 }'),

    ('h2', 'PriorityClass and preemption'),
    ('code', 'kubectl create priorityclass high --value=1000\n'
             'kubectl patch deployment app \\\n'
             '  -p \'{"spec":{"template":{"spec":{"priorityClassName":"high"}}}}\''),

    ('h2', 'Node affinity, pod anti-affinity'),
    ('code', 'affinity:\n'
             '  nodeAffinity:\n'
             '    requiredDuringSchedulingIgnoredDuringExecution:\n'
             '      nodeSelectorTerms:\n'
             '      - matchExpressions:\n'
             '        - { key: disk, operator: In, values: ["ssd"] }\n'
             '  podAntiAffinity:\n'
             '    requiredDuringSchedulingIgnoredDuringExecution:\n'
             '    - labelSelector:\n'
             '        matchExpressions:\n'
             '        - { key: app, operator: In, values: ["demo"] }\n'
             '      topologyKey: kubernetes.io/hostname'),

    ('h2', 'Manual scheduling and the Binding API'),
    ('p', 'A pod that does not exist yet can name its node. A pod that already exists cannot '
          '- nodeName is immutable - so you POST a Binding, which is what the scheduler does.'),
    ('code', 'spec:\n'
             '  nodeName: node01              # new pod: bypasses the scheduler entirely\n'
             '---\n'
             'apiVersion: v1                  # existing pod: bind it\n'
             'kind: Binding\n'
             'metadata: { name: orphan-pod, namespace: ns }\n'
             'target: { apiVersion: v1, kind: Node, name: node01 }'),

    ('h2', 'PodDisruptionBudget and draining'),
    ('p', 'If a drain hangs on "would violate the pod disruption budget", relax the PDB - do '
          'not delete it.'),
    ('code', 'kubectl drain <node> --ignore-daemonsets --delete-emptydir-data\n'
             'kubectl patch pdb guard --type=merge -p \'{"spec":{"maxUnavailable":1}}\'\n'
             'kubectl uncordon <node>'),

    ('h2', 'LimitRange and ResourceQuota'),
    ('p', 'A ResourceQuota on cpu/memory makes every new pod declare requests and limits or be '
          'rejected. A LimitRange supplies the defaults that keep the namespace usable. That '
          'interaction is the examinable part.'),
    ('code', 'kubectl create quota compute-quota --hard=cpu=2,memory=2Gi,pods=5'),

    ('h2', 'StatefulSet with volumeClaimTemplates'),
    ('p', 'Each replica gets its own PVC named <template>-<statefulset>-<ordinal>. '
          'volumeClaimTemplates is a sibling of template, not a child, and serviceName must '
          'name a headless Service.'),
    ('code', 'spec:\n'
             '  serviceName: web-svc          # must be headless (clusterIP: None)\n'
             '  template: { ... }\n'
             '  volumeClaimTemplates:         # SIBLING of template\n'
             '  - metadata: { name: www }\n'
             '    spec:\n'
             '      accessModes: ["ReadWriteOnce"]\n'
             '      resources: { requests: { storage: 1Gi } }'),

    ('h2', 'Default StorageClass'),
    ('p', 'Two defaults is undefined behaviour: set the new one and clear the old one.'),
    ('code', 'kubectl patch storageclass fast \\\n'
             '  -p \'{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}\'\n'
             'kubectl get sc      # exactly ONE should say (default)'),

    ('h2', 'Manual PV with node affinity'),
    ('p', 'A hostPath or local PV must be pinned to the node that holds the data. '
          'storageClassName: "" is not the same as omitting the field.'),
    ('code', 'spec:\n'
             '  capacity: { storage: 1Gi }\n'
             '  accessModes: ["ReadWriteOnce"]\n'
             '  persistentVolumeReclaimPolicy: Retain\n'
             '  storageClassName: ""\n'
             '  hostPath: { path: /mnt/data }\n'
             '  nodeAffinity:\n'
             '    required:\n'
             '      nodeSelectorTerms:\n'
             '      - matchExpressions:\n'
             '        - { key: kubernetes.io/hostname, operator: In, values: ["node01"] }'),

    ('h2', 'ClusterRole aggregation'),
    ('p', 'The aggregate has EMPTY rules; the controller fills them from labelled ClusterRoles. '
          'Rules you write there are overwritten.'),
    ('code', 'aggregationRule:\n'
             '  clusterRoleSelectors:\n'
             '    - matchLabels: { rbac.example.com/aggregate: "true" }\n'
             'rules: []'),

    ('h2', 'CRDs'),
    ('p', 'kubectl explain reads the schema a CRD published, so it documents third-party '
          'resources exactly like built-ins.'),
    ('code', 'kubectl get crd\n'
             'kubectl api-resources --api-group=cert-manager.io\n'
             'kubectl explain certificate.spec.subject'),

    ('h2', 'kubectl patch'),
    ('p', 'Three patch types, and picking the wrong one is how people destroy a spec.'),
    ('code', '# strategic merge - merges lists by key; ALWAYS name the container\n'
             'kubectl patch deployment web -p \'{"spec":{"template":{"spec":{"containers":\n'
             '  [{"name":"nginx","resources":{"limits":{"cpu":"500m"}}}]}}}}\'\n'
             '\n'
             '# json - surgical, exact path\n'
             'kubectl patch svc web --type=json \\\n'
             '  -p=\'[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]\'\n'
             '\n'
             '# merge - replaces whole sub-objects\n'
             'kubectl patch pdb guard --type=merge -p \'{"spec":{"maxUnavailable":1}}\''),

    ('h2', 'Installing a CNI'),
    ('p', 'If the requirement mentions network policy enforcement, Flannel is disqualified - it '
          'provides pod networking but no policy engine. A node stuck NotReady with "cni plugin '
          'not initialized" means no CNI is installed.'),
    ('code', 'kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml'),

    ('h2', 'Container runtime (cri-dockerd / containerd)'),
    ('code', 'crictl ps -a                    # the fallback when kubectl is down\n'
             'crictl logs <container-id>\n'
             'systemctl status containerd\n'
             'sysctl -w net.ipv4.ip_forward=1\n'
             'sysctl -w net.bridge.bridge-nf-call-iptables=1'),
]

APPENDIX_C = [
    ('h1', 'Appendix C - corrections applied to this copy'),
    ('p', 'Fourteen text fixes were applied to the original document. If you also hold the '
          'original, these are the differences.'),
    ('h2', 'Wrong DNS names (Service Networking Q1)'),
    ('p', 'A Service FQDN is <service>.<namespace>.svc.cluster.local - the svc label was '
          'missing. And <pod_name>.local is not a Kubernetes record: pod records are '
          '<pod-ip-with-dashes>.<namespace>.pod.cluster.local. The task is graded on file '
          'contents, so the original recorded failed lookups.'),
    ('h2', 'A grep that silently returned nothing (Architecture Q12)'),
    ('p', 'grep \'INFO|ERROR\' without -E treats the pipe as a literal character and matches '
          'nothing, so the command ran cleanly and wrote an empty file. Corrected to grep -E. '
          'The same line also had a capitalised Kubectl and smart quotes.'),
    ('h2', 'Scheduling attributed to the controller manager (Troubleshooting Q5)'),
    ('p', 'The kube-scheduler assigns Pods to nodes; the kube-controller-manager creates them. '
          'The fix in that question was right but the reason was not, and the document '
          'contradicts itself at Q19 where it gets this correct. Symptom to component: no '
          'ReplicaSet created means controller-manager; pods Pending with no node assigned '
          'means scheduler; kubectl itself refusing to connect means apiserver or etcd.'),
    ('h2', 'Smaller fixes'),
    ('p', '/etc/Kubernetes/manifests/ corrected to lowercase in 2 places (paths are '
          'case-sensitive), and "K top nodes" / "K top pods -A" corrected to lowercase k in 8 '
          'places.'),
    ('h2', 'Known issues not fixed'),
    ('p', 'Architecture Q5 and Q15 are the same question duplicated, so the document holds 52 '
          'unique questions rather than the ~55 the introduction claims. Most terminal output '
          'lives in screenshots rather than text, so it cannot be searched or copied.'),
]


def render(blocks):
    out = []
    for kind, payload in blocks:
        if kind == 'h1':
            out.append(page_break())
            out.append(para(payload, style='Heading1'))
        elif kind == 'h2':
            out.append(para(payload, style='Heading2'))
        elif kind == 'p':
            out.append(para(payload))
        elif kind == 'code':
            out.extend(code_block(payload))
    return out


# ---------------------------------------------------------------- main

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    src, dst = sys.argv[1], sys.argv[2]
    work = tempfile.mkdtemp(prefix='ckadocx-')
    unpacked = os.path.join(work, 'unpacked')
    with zipfile.ZipFile(src) as z:
        z.extractall(unpacked)
    for root, _, files in os.walk(unpacked):
        for f in files:
            p = os.path.join(root, f)
            if os.path.islink(p):
                os.unlink(p)

    skill = os.environ.get('DOCX_SKILL_DIR')
    if skill and os.path.exists(os.path.join(skill, 'scripts/merge_runs.py')):
        subprocess.run([sys.executable, os.path.join(skill, 'scripts/merge_runs.py'), unpacked],
                       check=False, capture_output=True)

    doc = os.path.join(unpacked, 'word/document.xml')
    raw = open(doc, encoding='utf-8').read()
    for pfx, uri in re.findall(r'xmlns:([A-Za-z0-9]+)="([^"]+)"', raw[:6000]):
        if not re.fullmatch(r'ns\d+', pfx):
            ET.register_namespace(pfx, uri)
    tree = ET.parse(doc)
    body = tree.getroot().find(q('body'))

    # --- pass 1: headings, code styling, corrections, and index harvesting
    stats = {'headings': 0, 'code': 0, 'fixes': 0}
    index_rows = [['Section', 'Question', 'Cluster', 'Task']]
    section = None
    pending = None
    for p in list(body.iter(q('p'))):
        txt = ''.join(n.text or '' for n in p.iter(q('t')))
        style = None
        pPr = p.find(q('pPr'))
        if pPr is not None and pPr.find(q('pStyle')) is not None:
            style = pPr.find(q('pStyle')).get(q('val'))
        if style == 'Heading1':
            section = txt.strip()
        if re.match(r'^\s*Question\s+\d+\s*:', txt):
            ordered_set(get_ppr(p), 'pStyle', PPR_ORDER, val='Heading2')
            stats['headings'] += 1
            pending = {'sec': section or '', 'q': txt.strip().rstrip(':'), 'cluster': '', 'task': ''}
            index_rows.append(pending)
            continue
        if pending is not None and txt.strip():
            m = re.search(r'use-context (cluster\d)', txt)
            if m and not pending['cluster']:
                pending['cluster'] = m.group(1)
            elif not pending['task'] and not txt.lower().startswith(('for this question', 'kubectl config')):
                t = re.sub(r'\s+', ' ', txt.strip())
                pending['task'] = (t[:150] + '...') if len(t) > 150 else t
                pending = None
        if is_code(txt):
            pPr = get_ppr(p)
            ordered_set(pPr, 'shd', PPR_ORDER, val='clear', color='auto', fill='F3F4F6')
            ordered_set(pPr, 'ind', PPR_ORDER, left='227')
            ordered_set(pPr, 'spacing', PPR_ORDER, before='20', after='20')
            for r in p.iter(q('r')):
                rPr = r.find(q('rPr'))
                if rPr is None:
                    rPr = ET.Element(q('rPr'))
                    r.insert(0, rPr)
                ordered_set(rPr, 'rFonts', RPR_ORDER, ascii='Consolas', hAnsi='Consolas', cs='Consolas')
                ordered_set(rPr, 'sz', RPR_ORDER, val='18')
                ordered_set(rPr, 'szCs', RPR_ORDER, val='18')
            stats['code'] += 1
        for match, build, _ in CORRECTIONS:
            if match(txt):
                new = build(txt)
                if new != txt and set_text(p, new):
                    stats['fixes'] += 1
                break

    rows = [['Section', 'Question', 'Cluster', 'Task']]
    for r in index_rows[1:]:
        rows.append([r['sec'][:28], r['q'], r['cluster'] or '-', r['task'] or ''])

    # --- section mix vs official weighting
    official = {'Troubleshooting': 30, 'Architecture, Install and Maintenance': 25,
                'Service Networking': 20, 'Scheduling': 15, 'Storage': 10}
    counts = {}
    for r in index_rows[1:]:
        counts[r['sec']] = counts.get(r['sec'], 0) + 1
    total = sum(v for k, v in counts.items() if k in official)
    section_rows = [['Knowledge area', 'In this doc', 'Exam weight', 'Verdict']]
    for k, wt in sorted(official.items(), key=lambda kv: -kv[1]):
        c = counts.get(k, 0)
        pct = (c / total * 100) if total else 0
        verdict = 'over-represented' if pct > wt + 3 else ('UNDER-represented' if pct < wt - 3 else 'about right')
        section_rows.append([k, f'{c} q ({pct:.0f}%)', f'{wt}%', verdict])

    cl = {}
    for r in index_rows[1:]:
        if r['cluster']:
            cl[r['cluster']] = cl.get(r['cluster'], 0) + 1
    cluster_rows = [['Cluster', 'Questions', 'Note']]
    for c in sorted(cl):
        note = 'barely exercised here' if cl[c] <= 4 else ''
        cluster_rows.append([c, str(cl[c]), note])

    # --- assemble
    front = toc_block() + front_matter(rows, section_rows, cluster_rows)
    for i, el in enumerate(front):
        body.insert(i, el)

    sectPr = body.find(q('sectPr'))
    tail = render(APPENDIX_A) + render(APPENDIX_B) + render(APPENDIX_C)
    for el in tail:
        if sectPr is not None:
            body.insert(list(body).index(sectPr), el)
        else:
            body.append(el)

    tree.write(doc, encoding='UTF-8', xml_declaration=True)

    # ElementTree only emits namespaces it used; mc:Ignorable still references the rest
    with zipfile.ZipFile(src) as z:
        orig_root = re.search(r'<w:document\b[^>]*>', z.read('word/document.xml').decode('utf-8')).group(0)
    orig_ns = dict(re.findall(r'xmlns:([A-Za-z0-9]+)="([^"]+)"', orig_root))
    new = open(doc, encoding='utf-8').read()
    m = re.search(r'<w:document\b[^>]*>', new)
    have = set(re.findall(r'xmlns:([A-Za-z0-9]+)=', m.group(0)))
    add = ''.join(f' xmlns:{k}="{v}"' for k, v in orig_ns.items() if k not in have)
    if add:
        open(doc, 'w', encoding='utf-8').write(new[:m.start()] + m.group(0)[:-1] + add + '>' + new[m.end():])

    if os.path.exists(dst):
        os.remove(dst)
    dst_abs = os.path.abspath(dst)
    subprocess.run(['zip', '-Xrq', dst_abs, '.'], cwd=unpacked, check=True)
    shutil.rmtree(work, ignore_errors=True)

    print(f'questions promoted to Heading 2 : {stats["headings"]}')
    print(f'code paragraphs restyled        : {stats["code"]}')
    print(f'text corrections applied        : {stats["fixes"]}')
    print(f'index rows generated            : {len(rows) - 1}')
    print(f'wrote {dst}')


if __name__ == '__main__':
    main()
