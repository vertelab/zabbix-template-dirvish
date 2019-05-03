#!/usr/bin/python

import fnmatch
import os
import os.path
import datetime
import re


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
    
    
for vault in get_vaults('/srv/backup'):
    # ~ print get_vault_hist('/srv/backup',vault)
    print get_vault_summary('/srv/backup',vault)


# check last_summary
# get status 


