all: solver compression helmholtz # protonet-tester versionDemo logoDrawString

.PHONY: solver compression helmholtz # protonet-tester versionDemo logoDrawString

clean:
	dune clean
	rm -f solver
	rm -f compression
	rm -f helmholtz
#	rm -f protonet-tester
#	rm -f versionDemo
#	rm -f logoDrawString
#	rm -f data/geom/logoDrawString

solver:
	dune build solvers/bin/solver.exe
	mv solvers/bin/solver.exe solver

compression:
	dune build solvers/bin/compression.exe
	mv solvers/bin/compression.exe compression

helmholtz:
	dune build solvers/bin/helmholtz.exe
	mv solvers/bin/helmholtz.exe helmholtz

# protonet-tester:
# 	dune build solvers/protonet_tester.exe
# 	mv solvers/protonet_tester.exe protonet-tester

# versionDemo:
# 	dune build solvers/versionDemo.exe
# 	mv solvers/versionDemo.exe versionDemo

# logoDrawString:
# 	dune build solvers/logoDrawString.exe
# 	mv solvers/logoDrawString.exe logoDrawString
# 	ln -sf ../../logoDrawString data/geom/logoDrawString
