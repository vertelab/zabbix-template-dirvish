#!/usr/bin/python

import fnmatch
import os
import os.path
import datetime
import re
from hurry.filesize import size
import argparse

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "c:v", ["help", "output="])
    except getopt.GetoptError as err:
        # print help information and exit:
        print(err)  # will print something like "option -a not recognized"
        usage()
        sys.exit(2)
    output = None
    verbose = False
    for o, a in opts:
        if o == "-v":
            verbose = True
        elif o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-o", "--output"):
            output = a
        else:
            assert False, "unhandled option"
    # ...



def read_config():
    f = open('/etc/dirvish/master.conf','r')
    lines = f.read().split('\n')
    f.close()
    master = {}
    index = 0
    while index < len(lines):
        if 'bank' in lines[index]:
            index += 1
            master['bank'] = lines[index].strip()
        if 'Runall' in lines[index]:
            master['Runall'] = []
            index += 1
            while not (lines[index] == '\n' or lines[index] == ''):
                # ~ print lines[index],len(lines[index])
                if lines[index].split()[0][0] != '#':
                    master['Runall'].append(lines[index].split())
                index += 1
        index += 1
    return master
    
    

def get_vaults(bank):
    vaults = []
    for vault in os.listdir(bank):
        if fnmatch.fnmatch(vault, '*'):
            if os.listdir('%s/%s/dirvish' % (bank,vault)):
                vaults.append(vault)
                
    return vaults
    
#print get_vaults('/srv/backup')

def get_vault_hist(bank,vault):
    hist_file = '%s/%s/dirvish/default.hist' % (bank,vault)
    (date,last,rule) = (False,'','')
    if os.path.exists(hist_file):
        with open(hist_file,'r') as f:
            lines = f.readlines()
        if len(lines) > 0:
            last_line = [l.strip() for l in lines][-1]
            
            l = last_line.split('\t')
            # ~ print ('%s %s' % (l[1].strip(),l[2].strip())),l[3].strip()
            (date,last,rule) = (l[0].strip(),('%s %s' % (l[1].strip(),l[2].strip())), l[3].strip())
    return (vault,date,last,rule)


def get_vault_summary(bank,vault):
    date = (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y%m%d')
    summary_file = '%s/%s/%s/summary' % (bank,vault,date,)
    hist_file = '%s/%s/dirvish/default.hist' % (bank,vault)
    (status,status_text,date,last,rule) = ('Error','',False,'','')
    if os.path.exists(summary_file):
        with open(summary_file,'r') as f:
            lines = f.readlines()
        if len(lines) > 0:
            last_line = [l.strip() for l in lines][-1]
            status_text = re.match('Status: (.*)$',last_line).group(1)
            status = 'Error'
            if 'success' in status_text:
                status = 'Ok'
            elif 'warning' in status_text:
                status = 'Warning'
    if os.path.exists(hist_file):
        with open(hist_file,'r') as f:
            lines = f.readlines()
        if len(lines) > 0:
            last_line = [l.strip() for l in lines][-1]
            l = last_line.split('\t')
            (date,last,rule) = (l[0].strip(),('%s %s' % (l[1].strip(),l[2].strip())), l[3].strip())

    return (vault,status,status_text,date,last,rule)


# ~ print config    

# ~ for vault in [v[0] for v in config['Runall']]:
    # ~ print get_vault_hist('/srv/backup',vault)
    # ~ print get_vault_summary(config['bank'],vault)


# check last_summary
# get status 

def _get_os(cmd):
    f = os.popen(cmd)
    result = f.read()
    f.close()
    return result 


def get_status(vault,bank):
    (vault,status,status_text,date,last,rule) = get_vault_summary(bank,vault)
    if status == 'Ok':
        return 1
    else:
        return 0

def get_change_size(vault,bank):
    (vault,status,status_text,date,last,rule) = get_vault_summary(bank,vault)
    first_size = int(_get_os("du -s %s/%s/%s" % (bank,vault,last.split()[2])).split()[0])
    last_size = int(_get_os("du -s %s/%s/%s" % (bank,vault,date)).split()[0])
    return size(first_size - last_size)
def get_total_size(vault,bank):
    (vault,status,status_text,date,last,rule) = get_vault_summary(bank,vault)
    return size(_get_os("du -s %s/%s" % (bank,vault)))
    
def get_start_time(vault,timestamp,bank):
    config = read_config()
    pos = 0
    for index,v in enumerate(config['Runall']):
        if v[0] == vault:
            pos = index
    if pos > 0:
        vault_prev = config['Runall'][pos - 1][0]
        (x,x,x,x,last_prev,x) = get_vault_summary(bank,vault_prev)
        (x,x,x,x,last,x) = get_vault_summary(bank,vault)
        # ~ print last_prev.split()[1],last.split()[1]
        return last_prev.split()[1]
    else:
        return config['Runall'][0][1]+':00'

def get_stop_time(vault,timestamp,bank):
    (x,x,x,x,last,x) = get_vault_summary(bank,vault)
    return last.split()[1]

def do_discover():
    config = read_config()
    vault_dict = {v[0]:{'fullname': v[0], 'starttime': v[1]} for v in config['Runall']}
    return """{
    'data':[
%s
        ]
}
""" % ',\n'.join(["""           {
                '{#NAME}':'%s',
                '{#FULLNAME}':'%s',
                '{#STARTTIME}':'%s',
            }""" % (v,vault_dict[v]['fullname'],vault_dict[v]['starttime']) for v in vault_dict.keys()])
        

if __name__ == "__main__":
    print do_discover()