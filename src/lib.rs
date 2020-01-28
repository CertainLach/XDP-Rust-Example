#![crate_type = "staticlib"]
#![feature(lang_items)]
#![no_std]

#[repr(C)]
pub struct xdp_md {
	data: u32,
	data_end: u32,
	data_meta: u32,
	ingress_ifindex: u32,
	rx_queue_index: u32,
}

#[repr(C)]
pub enum XdpAction {
	Aborted = 0,
	Drop = 1,
	Pass = 2,
	Tx = 3,
	Redirect = 4,
}

type BPFTracePrintk = unsafe extern "C" fn(fmt: *const u8, size: i32, ...) -> i32;

macro_rules! traceln {
    ($line: expr $(, $x:expr )*) => {
        const len: usize = $line.len() + 2;
        let bpf_trace_printk: BPFTracePrintk = unsafe { core::mem::transmute(6u64) };
        unsafe{
        bpf_trace_printk(
            concat!($line, "\n\0").as_bytes().as_ptr() as *const u8,
            len as i32,
            $(
                $x,
            )*
            );
        }
    };
}

#[no_mangle]
#[link_section = "prog"]
pub extern "C" fn main(ctx: &mut xdp_md) -> XdpAction {
	traceln!("Hello from ebpf world! %p %i", ctx, 2 + 3);
	XdpAction::Pass
}
