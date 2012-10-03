cryo.arx: 
	git archive HEAD | bzip2 | arx tmpx -rm! - -e ./bin/bootstrap_cryo.sh FOO=bar > cryo.arx

clean: 
	rm cryo.arx
