package cmd

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/fatih/color"
)

// listCmd represents the list command
var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Lists available keeps",
	Run: func(cmd *cobra.Command, args []string) {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			log.Fatal(err)
			return
		}

		keepDir := filepath.Join(homeDir, ".dotkeep")

		keeps, err := os.ReadDir(keepDir)
		if err != nil {
			color.Red(" No keeps available")
			return
		}

		if keeps != nil {
			color.Green("󰌨 Available keeps:")
			for _, keep := range keeps {
				if keep.IsDir() == true {
					fmt.Printf(" - %s\n", keep.Name())
				}
			}
		} else {
			color.Red(" No keeps available")
		}
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
