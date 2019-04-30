#/usr/bin/python
import yaml
config = yaml.safe_load(open("/etc/dirvish/master.conf"))

print "%s" % config

