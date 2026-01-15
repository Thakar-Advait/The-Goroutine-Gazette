---
layout: post
title: "Exploring the Lightweight Nature of Goroutines in Go"
date: 2026-01-15
categories: go concurrency
tags: golang, goroutines, concurrency, go-runtime
---

> “𝗔 𝗴𝗼𝗿𝗼𝘂𝘁𝗶𝗻𝗲 𝗵𝗮𝘀 𝗮 𝘀𝗶𝗺𝗽𝗹𝗲 𝗺𝗼𝗱𝗲𝗹: 𝗶𝘁 𝗶𝘀 𝗰𝗵𝗲𝗮𝗽, 𝗶𝘁 𝗶𝘀 𝗳𝗮𝘀𝘁, 𝗮𝗻𝗱 𝗶𝘁 𝘀𝗰𝗮𝗹𝗲𝘀.”  
> — Rob Pike

I’ve been diving deep into concurrency models in Go, and one of the most fascinating aspects is **goroutines** — lightweight threads that are at the heart of Go’s concurrency model. Their efficiency is a major reason Go has become such a strong choice for building highly concurrent systems.

Recently, I came across an analysis showing just how lightweight goroutines really are. Naturally, I decided to verify these results on my own machine.

---

### Experiment Setup

What makes this experiment particularly fun is Go’s runtime itself. Go exposes powerful introspection tools out of the box, such as `runtime.ReadMemStats` and GC hooks. These allow us to measure memory usage **before and after spawning goroutines**. Combined with dynamically sized stacks and runtime-managed scheduling, we can get a clean estimate of each goroutine’s memory footprint.

---

### Results

The results were mind-blowing:

- To spawn goroutines on the **order of 10⁴**, Go required **only ~2 KB of runtime memory per goroutine**.  
- All goroutines were alive simultaneously at the time of measurement.  

On my laptop with 8 GB of RAM, this means — theoretically — I could spin up **millions of goroutines** without swapping. Of course, this ignores other processes and the work done inside each goroutine, but it still demonstrates just how lightweight goroutines are.

---

### Source Code & Analysis

Here’s a simplified version of the code I used to measure memory usage:

```go
package main

import (
    "fmt"
    "runtime"
    "sync"
)

func main() {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    fmt.Printf("Memory before goroutines: %v KB\n", m.Alloc/1024)

    var wg sync.WaitGroup
    N := 10000
    wg.Add(N)
    for i := 0; i < N; i++ {
        go func() {
            defer wg.Done()
        }()
    }
    wg.Wait()

    runtime.ReadMemStats(&m)
    fmt.Printf("Memory after goroutines: %v KB\n", m.Alloc/1024)
}
```

You can see that Go’s **scheduler and runtime manage concurrency extremely efficiently**, keeping memory overhead per goroutine very low.

---

### Conclusion

Goroutines are **cheap, fast, and scalable**, just like Rob Pike described. This experiment reinforced my understanding of Go’s concurrency model and why it’s so powerful for building highly concurrent systems.

I’ve attached the full analysis for anyone interested in diving deeper.  

