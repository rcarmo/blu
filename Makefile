# Source code
PYFILES=$(wildcard *.py)
BYTECODE=$(PYFILES:.py=.pyc)
PROFILES=$(wildcard *.pstats)
CALL_DIAGRAMS=$(PROFILES:.pstats=.png)

repl:
	hy repl.hy

deps:
	pip install -U -r requirements.txt

clean:
	rm -f $(BYTECODE)
	rm -f $(PROFILES)
