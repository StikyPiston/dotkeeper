package cmd

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

type State struct {
	Keep  string `json:"keep"`
	Links []Link `json:"links"`
}

type Link struct {
	Source string `json:"source"`
	Target string `json:"target"`
}

// statusCmd represents the status command
var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "See the currently active keep",
	Long:  "Usage: dotkeeper status",
	Run: func(cmd *cobra.Command, args []string) {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			log.Fatal(err)
			return
		}

		stateFile := filepath.Join(homeDir, ".dotkeeper-state.json")

		state, err := os.ReadFile(stateFile)

		var data State

		err = json.Unmarshal(state, &data)
		if err != nil {
			fmt.Println("󰌩 No active keep")
			return
		}

		if data.Keep != "" {
			fmt.Println(" Active keep: %s", data.Keep)
		} else {
			fmt.Println("󰌩 No active keep")
		}
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
