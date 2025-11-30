sushi: sushi.asm
	fasm sushi.asm sushi
	chmod +x sushi

clean: sushi
	rm sushi

install: sushi
	mkdir -p ~/opt/bin
	mv sushi ~/opt/bin/sushi

