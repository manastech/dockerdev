package main

import (
	"log"
	"os"

	docker "github.com/fsouza/go-dockerclient"
)

func main() {
	cli, err := docker.NewClientFromEnv()
	if err != nil {
		log.Fatal(err)
	}

	listener := make(chan *docker.APIEvents, 10)
	filters := map[string][]string{
		"type":  {"container"},
		"event": {"create"},
	}
	opts := docker.EventsOptions{Filters: filters}
	err = cli.AddEventListenerWithOptions(opts, listener)
	if err != nil {
		log.Fatal(err)
	}

	domain := os.Getenv("DOMAIN_TLD")

	log.Println("Listening events")
	for {
		event := <-listener

		containerName := event.Actor.Attributes["name"]
		log.Printf("New container (%s) created\n", containerName)

		project, hasProject := event.Actor.Attributes["com.docker.compose.project"]
		service, hasService := event.Actor.Attributes["com.docker.compose.service"]
		oneoff := event.Actor.Attributes["com.docker.compose.oneoff"]

		if hasProject && hasService {
			config := docker.NetworkConnectionOptions{Container: event.Actor.ID}

			if oneoff == "False" {
				alias := service + "." + project + "." + domain
				log.Printf("Attaching %s to the shared network with alias %s\n", containerName, alias)
				config.EndpointConfig = &docker.EndpointConfig{
					Aliases: []string{alias},
				}
			} else {
				log.Printf("Attaching %s to the shared network\n", event.Actor.ID)
			}

			err := cli.ConnectNetwork("shared", config)
			if err != nil {
				log.Fatal(err)
			}
		}
	}
}
