.PHONY: run test clean

exe=olox

$(exe):
	@odin build . -debug -out:bin/$(exe)

run: $(exe)
	@./bin/$(exe) examples/expression.lox

test:
	@odin test . -all-packages -out:$(exe) && rm -rf $(exe)

clean:
	@clear && rm -rf bin/*