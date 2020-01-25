.PHONY: all clean inject

shellvm:
	git clone https://github.com/SheLLVM/SheLLVM shellvm

shellvm/build/llvm/shellvm.so: shellvm
	mkdir -p shellvm/build
	cd shellvm/build && cmake .. && make

target/release/xdp.ll: src/** shellvm/build/llvm/shellvm.so
	rm -rf target/release/deps

	# Compiles crate to llvm ir
	RUSTFLAGS="--emit llvm-ir -C opt-level=z" cargo build --release
	cp target/release/deps/*.ll $@
	# Inject license section and shellvm annotations
	sed -i '/target triple = "x86_64-unknown-linux-gnu"/a @_license = dso_local global [4 x i8] c"GPL\\00", section "license", align 1\n@.shellvm_main = private unnamed_addr constant [13 x i8] c"shellvm-main\\00", section "llvm.metadata"\n@.libname = private unnamed_addr constant [13 x i8] c"xdp_filter.c\\00", section "llvm.metadata"\n@llvm.global.annotations = appending global [1 x { i8*, i8*, i8*, i32 }] [{ i8*, i8*, i8*, i32 } { i8* bitcast (i32 (%xdp_md*)* @main to i8*), i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.shellvm_main, i32 0, i32 0), i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.libname, i32 0, i32 0), i32 4 }], section "llvm.metadata"' $@

	rm -rf target/release/deps

target/release/xdp.opt.ll: target/release/xdp.ll
	# eBPF have no data section
	opt -S -load shellvm/build/llvm/shellvm.so \
	-shellvm-prepare \
	-shellvm-global2stack -mergecalls -shellvm-flatten -shellvm-inlinectors \
	\
	$< > $@

target/release/xdp.o: target/release/xdp.opt.ll
	llc -march=bpf -filetype=obj -o $@ $<

clean:
	rm -f target/release/xdp.opt.ll target/release/xdp.ll target/release/xdp.o
	rm -rf target/release/deps

all: target/release/xdp.o

disasm: target/release/xdp.o
	llvm-objdump -S -no-show-raw-insn $<

attach: target/release/xdp.o
	@test $(DEVICE) || ( echo "DEVICE is not set" && exit 1 )
	ip -force link set dev $(DEVICE) xdp object $< verbose

detach:
	@test $(DEVICE) || ( echo "DEVICE is not set" && exit 1 )
	ip -force link set dev $(DEVICE) xdp off
