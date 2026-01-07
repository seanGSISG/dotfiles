# DGX Spark Performance & Optimization Deep-Dive

This document tracks real-world benchmarks and optimization strategies for the GB10 (Blackwell) architecture on the DGX Spark.

## 📊 Inference Engine Comparison
The choice of engine is the primary factor in throughput for the Spark's 128GB unified memory pool.

| Metric | llama.cpp | vLLM (Spark Build) | SGLang (Spark Build) |
| :--- | :--- | :--- | :--- |
| **Best For** | Single-user latency | Agentic / Multi-user | Blackwell MXFP4 |
| **gpt-oss-120b** | **60 t/s** (Small context) | 36 t/s | 53 t/s (Triton Kernels) |
| **Clustering** | Poor (Layer Split) | **Excellent (Tensor Parallel)** | Experimental |
| **Concurrency** | Limited / Unoptimized | **Highly Optimized** | Optimized |
| **Protocols** | OpenAI / Ollama | OpenAI / Responses API | OpenAI |

### Engine Nuances
* **llama.cpp:** Significantly faster for single-stream generation but lacks native MXFP4 kernels for Blackwell in the main branch.
* **vLLM:** The "Day 1" platform for new architectures. While single-user speed is lower, it provides **2x performance gains** in clusters via Tensor Parallelism.
* **SGLang:** Offers optimized **Triton MXFP4 kernels** specifically for the Spark, closing the gap with `llama.cpp` for large models.

## 📉 Quantization Reality Check (NVFP4 vs. AWQ)
While NVFP4 is the native "aggressive" format for Blackwell, current software support dictates the following priorities:

1. **AWQ 4-bit (Current Winner):** Shows **18–32% higher throughput** than NVFP4 in vLLM due to more mature kernel support.
2. **NVFP4 (Next-Gen):** Provides near-FP8 accuracy (<1% loss) and reduces model footprint. Currently faces higher latency (~51ms ITL vs 39ms for AWQ).
3. **FP8 vs. AWQ 8-bit:** FP8 generally offers better prompt processing (prefill), while AWQ 8-bit slightly leads in token generation (decode).

## 🕸️ Clustering: Dual Spark Performance
Using the **ConnectX-7 200G** interconnect is mandatory for scaling to models like Llama 3.1 405B.

* **Infiniband/RoCE:** Mandatory for cluster performance. Ethernet-based NCCL adds significant latency.
* **vLLM Scaling:** Scaling from 1 to 2 nodes using Tensor Parallelism can result in a **2x throughput increase** for dense models.
* **llama.cpp Scaling:** RPC mechanism lacks RoCE support and uses Layer Splitting, which often leads to a *decrease* in performance when clustered.

## ⚙️ Critical Optimizations
* **Model Loading:** Standard `mmap` is slow on current kernels (6.11/6.14). Use `--no-mmap` in `llama.cpp` or `--safetensors-load-strategy eager` in vLLM to reduce load times from minutes to seconds.
* **NVMe Read-Ahead:** Increase the buffer for faster I/O:
    ```bash
    sudo bash -c "echo 8192 > /sys/block/nvme0n1/queue/read_ahead_kb"
    ```
* **CPU Idle States:** Disabling deep idle states can reduce RPC wake-up latency in cluster modes:
    ```bash
    sudo cpupower idle-set -D 0
    ```

---
*Reference benchmarks based on vLLM v0.11.1rc4.dev and llama.cpp commit 7db35a7.*
https://github.com/ggml-org/llama.cpp/discussions/16578
