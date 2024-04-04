package main

import (
	"context"
	"fastack/docker"
)

func main() {
	ctx := context.Background()
	d := docker.New(ctx)
	d.CreateAndRun(
		"mongo",
		"8080",
		"8080",
		"mongo-go-cli",
	)
}
