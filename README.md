# Rust XDP example

## Why

Because XDP is awesome. Rust is also awesome

## Building

```sh
make all
```

## Testing

Code in this repo just drops all packets received

To start executing code run this command (Replace `enp3s0` with correct network device)

```sh
env DEVICE=enp3s0 sudo -E make inject
```

To see logs enter

```sh
echo -n 1 | sudo tee /sys/kernel/debug/tracing/options/trace_printk
sudo cat /sys/kernel/debug/tracing/trace_pipe
```

## TODO

Publish complete api crate

## Built With

- [Shellvm](https://github.com/SheLLVM/SheLLVM) - eBPF have almost same limitations as shellcode
