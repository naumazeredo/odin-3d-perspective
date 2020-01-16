# @Todo: dependencies (currently a folder dependency)
SRC=odinstein

all:
	odin run $(SRC)

build:
	odin build $(SRC)

run:
	.\$(SRC)
