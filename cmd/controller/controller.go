package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"

	"github.com/ricoberger/siri-cluster-controller/pkg/version"

	"github.com/julienschmidt/httprouter"
)

var (
	showVersion   = flag.Bool("version", false, "Show version information.")
	listenAddress = flag.String("listen-address", ":8080", "Address to listen on for web interface.")
)

// KubectlRequest is the structure of a request to run kubeclt command.
type KubectlRequest struct {
	Kubectl string `json:"kubectl"`
}

// HealthHandler always returns status code 200.
func HealthHandler(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	w.WriteHeader(http.StatusOK)
	return
}

// KubectlHandler handles kubectl requests.
func KubectlHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	var req KubectlRequest

	if r.Body == nil {
		http.Error(w, "request body is required", 400)
		return
	}

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	if req.Kubectl == "" {
		http.Error(w, "kubectl command is required", 400)
		return
	}

	cmd := exec.Command("kubectl", strings.Split(req.Kubectl, " ")...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Error while running kubectl: %#v", err)

		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "%s\n\n%s", err.Error(), string(out))
		return
	}

	fmt.Fprintf(w, string(out))
	return
}

func main() {
	// Parse command-line flags.
	flag.Parse()

	// Show version information if the "-version" flag is present.
	if *showVersion {
		v, err := version.Print("siri-cluster-controller")
		if err != nil {
			log.Fatalf("Failed to print version information: %#v\n", err)
		}

		fmt.Fprintln(os.Stdout, v)
		os.Exit(0)
	}

	fmt.Printf("Starting server %s\n", version.Info())
	fmt.Printf("Build context %s\n", version.BuildContext())
	fmt.Printf("siri-cluster-controller listening on %s\n", *listenAddress)

	// Create the router and start the HTTP server.
	// The default listen address ":8080" can be overwritten with the "-listen-address" flag.
	router := httprouter.New()
	router.GET("/", HealthHandler)
	router.POST("/", KubectlHandler)

	err := http.ListenAndServe(*listenAddress, router)
	if err != nil {
		log.Fatalf("Fatal error: %#v\n", err)
	}
}
