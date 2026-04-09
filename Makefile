.PHONY: install uninstall

install: main.c
	@gcc -o cnew main.c
	@cp cnew /usr/local/bin/cnew
	@chmod +rx /usr/local/bin/cnew

uninstall:
	@rm -rf /usr/local/bin/cnew
