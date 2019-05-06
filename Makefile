all : dependent.tmp configs.tmp scripts.tmp 
	@echo Complete

dependent.tmp:
	@sudo apt -y install zabbix-agent
	@sudo pip install hurry.filesize
	@touch dependent.tmp

configs.tmp: configs/sudoers.d--zabbix-dirvish  configs/zabbix-dirvish.conf
	@sudo cp configs/sudoers.d--zabbix-dirvish  /etc/sudoers.d
	@sudo cp configs/zabbix-dirvish.conf /etc/zabbix/zabbix_agentd.conf.d
	@touch configs.tmp

scripts.tmp: scripts/dirvish_backup_stats.pl  scripts/discover.dirvish-repos.pl
	@sudo mkdir -p /etc/zabbix/scripts/agentd/dirvish
	@sudo cp -r scripts/dirvish_backup_stats.pl  scripts/discover.dirvish-repos.pl /etc/zabbix/scripts/agentd/dirvish
	@touch scripts.tmp

clean:
	@rm -f *tmp
	@echo "Cleaned up"
	
