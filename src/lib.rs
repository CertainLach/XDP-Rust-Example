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

#[no_mangle]
#[link_section = "prog"]
pub extern "C" fn main(ctx: &mut xdp_md) -> XdpAction {
	let bpf_trace_printk: unsafe extern "C" fn(fmt: &[u8; 27], size: i32, ...) -> i32 =
		unsafe { core::mem::transmute(6u64) };
	unsafe {
		bpf_trace_printk(b"Hello from ebpf world! %p\n\0", 27, ctx);
	};
	XdpAction::Pass
}
