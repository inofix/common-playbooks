
import jinja2
import ruamel.yaml

yaml = ruamel.yaml.YAML(typ='safe', pure=True)

with open("/home/mic/2/ch/inofix/full_kb/common-playbooks/roles/setup-acmesh/defaults/main.yml", "r") as f:
    d = yaml.load(f.read())
with open("/home/mic/2/ch/inofix/full_kb/common-playbooks/roles/setup-acmesh/vars/main.yml", "r") as f:
    v = yaml.load(f.read())

for k in v.keys():
    d[k] = v[k]

with open("/home/mic/2/ch/inofix/full_kb/common-playbooks/roles/setup-acmesh/templates/add-cert.name.sh.j2", "r") as f:
    j2 = jinja2.Template(f.read())

d['item'] = "{{ d['acme__certificate']['available']['net_example'] }}"
p = j2.render(d)

print(p)

