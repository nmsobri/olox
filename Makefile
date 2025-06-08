exe=olox

$(exe):
	@odin build . -debug -out:bin/$(exe)

run: $(exe)
	@./bin/$(exe) examples/main.lox

clean:
	@clear && rm -rf bin/*