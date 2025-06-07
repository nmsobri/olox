exe=olox

$(exe):
	@odin build . -debug -out:bin/$(exe)

run: $(exe)
	@./bin/$(exe)

clean:
	@rm -rf bin/*