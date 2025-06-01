exe=ciio

$(exe):
	@odin build . -debug -out:bin/$(exe)

run: $(exe)
	@./bin/ciio