.PHONY: build 11.6 10.2

build:
	rm build/*.swf && make 11.6 && make 10.2

11.6:
	./gradlew build -Ptarget=11.6 && mv build/11.6/Scratch.swf build/Scrap.swf && rm -rf build/11.6;

10.2:
	./gradlew build -Ptarget=10.2 && mv build/10.2/ScratchFor10.2.swf build/ScrapFor10.2.swf && rm -rf build/10.2;
