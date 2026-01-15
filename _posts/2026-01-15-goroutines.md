---
layout: post
title: "Exploring the Lightweight Nature of Goroutines in Go"
date: 2026-01-15
categories: go concurrency
tags: golang, goroutines, concurrency, go-runtime
---

> "𝗔 𝗴𝗼𝗿𝗼𝘂𝘁𝗶𝗻𝗲 𝗵𝗮𝘀 𝗮 𝘀𝗶𝗺𝗽𝗹𝗲 𝗺𝗼𝗱𝗲𝗹: 𝗶𝘁 𝗶𝘀 𝗰𝗵𝗲𝗮𝗽, 𝗶𝘁 𝗶𝘀 𝗳𝗮𝘀𝘁, 𝗮𝗻𝗱 𝗶𝘁 𝘀𝗰𝗮𝗹𝗲𝘀."  
> — Rob Pike

I've been diving deep into concurrency models in Go, and one of the most fascinating aspects is **goroutines** — lightweight threads that are at the heart of Go's concurrency model. Their efficiency is a major reason Go has become such a strong choice for building highly concurrent systems.

Recently, I came across an analysis showing just how lightweight goroutines really are. Naturally, I decided to verify these results on my own machine.

---

### Experiment Setup

What makes this experiment particularly fun is Go's runtime itself. Go exposes powerful introspection tools out of the box, such as `runtime.ReadMemStats` and GC hooks. These allow us to measure memory usage **before and after spawning goroutines**. Combined with dynamically sized stacks and runtime-managed scheduling, we can get a clean estimate of each goroutine's memory footprint.

---

### Source Code & Analysis

Here's the code I used to measure memory usage:

```go
package main

import (
	"fmt"
	"runtime"
	"sync"
)

func main() {
	// memConsumed is a helper function to report current memory usage.
	// It forces a garbage collection before reading memory stats to get a more accurate snapshot.
	memConsumed := func() uint64 {
		runtime.GC() // Perform a garbage collection
		var s runtime.MemStats
		runtime.ReadMemStats(&s) // Read memory statistics into s
		return s.Sys              // Return the total allocated memory (Sys)
	}

	// c is an unbuffered channel that will never be written to.
	// This ensures goroutines block indefinitely when trying to receive from it,
	// keeping them alive until the main function explicitly waits for them.
	var c <-chan interface{}
	var wg sync.WaitGroup // WaitGroup to synchronize the main goroutine with the spawned goroutines.

	// noop is the function that each goroutine will execute.
	// It signals the WaitGroup that it's done and then attempts to receive from channel c,
	// which will cause it to block.
	noop := func() { wg.Done(); <-c }

	// Define the number of goroutines to create (10,000).
	const numGoroutines = 1e4 // 10,000 goroutines

	// Add the number of goroutines to the WaitGroup counter.
	wg.Add(numGoroutines)

	// Measure memory before spawning goroutines.
	before := memConsumed()

	// Spawn numGoroutines goroutines, each running the noop function.
	for i := numGoroutines; i > 0; i-- {
		go noop()
	}

	// Wait for all goroutines to signal they are "done" via wg.Done().
	// Note: The goroutines actually block after wg.Done() due to `<-c`,
	// but wg.Wait() only cares about the Done calls.
	wg.Wait()

	// Measure memory after all goroutines have been spawned and `wg.Done()` has been called by all.
	after := memConsumed()

	// Print the memory difference per 1000 goroutines in kilobytes.
	// This calculates the average memory overhead for each goroutine.
	fmt.Printf("%.3fkb", float64(after-before)/numGoroutines/1000)
}
```

This implementation uses a clever technique: an unbuffered channel `c` that is never written to ensures all goroutines remain alive and blocked, allowing us to accurately measure their memory footprint. The `memConsumed` helper function forces garbage collection before measurement to get a clean snapshot. The result shows that Go's **scheduler and runtime manage concurrency extremely efficiently**, keeping memory overhead per goroutine very low (approximately 2.654 KB per goroutine in this case).

---

### Results

The results were mind-blowing:

- To spawn goroutines on the **order of 10⁴**, Go required **only ~2 KB of runtime memory per goroutine**.  
- All goroutines were alive simultaneously at the time of measurement.  

On my laptop with 8 GB of RAM, this means — theoretically — I could spin up **millions of goroutines** without swapping. Of course, this ignores other processes and the work done inside each goroutine, but it still demonstrates just how lightweight goroutines are.

The following table illustrates how goroutines scale with increasing memory, showing the impressive scalability:

![Analysis of goroutines possible within given memory]({{ "/assets/images/post2-analysis-image.jpeg" | relative_url }})

---

### Conclusion

Goroutines are **cheap, fast, and scalable**, just like Rob Pike described. This experiment reinforced my understanding of Go's concurrency model and why it's so powerful for building highly concurrent systems.

I've attached the full analysis for anyone interested in diving deeper.  
