# Set these if not defined already
# Source code
PYFILES=$(wildcard *.py)
BYTECODE=$(PYFILES:.py=.pyc)
PROFILES=$(wildcard *.pstats)
CALL_DIAGRAMS=$(PROFILES:.pstats=.png)

repl:
	python main.py

deps:
	pip install -U -r requirements.txt

clean:
	rm -f $(BYTECODE)
	rm -f $(PROFILES)

build: $(BYTECODE) 

# Render pstats profiler files into nice PNGs (requires dot)
%.png: %.pstats
	python tools/gprof2dot.py -f pstats $< | dot -Tpng -o $@

profile: $(CALL_DIAGRAMS)
