# Makefile

all:
	
database.json: tables/*.json Makefile
	cd tables; (echo "{"; for i in $$(ls *.json); do /bin/echo -n "  \"$$(echo $$i | sed s/.json//)\": "; cat $$i; echo ","; echo; done; echo "}") > ../database.json
	jq -e . $@ >/dev/null # fails, the trailing comma

validate:
	jq -e . database.json >/dev/null
