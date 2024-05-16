package docker

import (
	"context"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
	"github.com/docker/go-connections/nat"
)

type DockerStack struct {
	ctx context.Context
	cli *client.Client
}

func New(ctx context.Context) DockerStack {
	d := DockerStack{ctx, nil}
	cli, err := d.GetClient()
	if err != nil {
		panic(err)
	}
	d.cli = cli
	return d
}

func (d *DockerStack) GetClient() (*client.Client, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return nil, err
	}
	cli.NegotiateAPIVersion(d.ctx)
	return cli, nil
}

func (d DockerStack) GetContainerConfig(
	imageName string,
	exposedPort string,
	envValues []string,
) *container.Config {
	config := container.Config{
		Image:        imageName,
		ExposedPorts: nat.PortSet{nat.Port(exposedPort): struct{}{}},
		Env:          envValues,
	}
	return &config
}

func (d DockerStack) GetHostConfig(
	hostPort string,
) *container.HostConfig {
	config := container.HostConfig{
		PortBindings: map[nat.Port][]nat.PortBinding{nat.Port(hostPort): {{HostIP: "127.0.0.1", HostPort: hostPort}}},
	}
	return &config
}

func (d DockerStack) CreateAndRun(
	imageName string,
	exposedPort string,
	hostPort string,
	appName string,
	envValues []string,
) {

	containerConfig := d.GetContainerConfig(imageName, exposedPort, envValues)
	hostConfig := d.GetHostConfig(hostPort)

	resp, err := d.cli.ContainerCreate(
		d.ctx,
		containerConfig,
		hostConfig,
		nil,
		nil,
		appName,
	)
	if err != nil {
		panic(err)
	}

	if err := d.cli.ContainerStart(
		d.ctx,
		resp.ID,
		container.StartOptions{},
	); err != nil {
		panic(err)
	}
}
