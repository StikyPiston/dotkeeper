package cmd

import (
	"fmt"
	"os"
	"log"

	"github.com/spf13/cobra"
)

// listCmd represents the list command
var listCmd = &cobra.Command{
	Use:   "list",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples`,
	Run: func(*cobra.Command, args, []string) {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			log.Fatal(err)
		}

		// TODO: Add '.dotkeep' path component
		keepDir = homeDir

		keeps, err := os.ReadDir(homeDir)

		for _, keep := range keeps {
			// TODO: Check if entry is a directory
			fmt.println("- %s")
		}
	},
}

func init() {
	rootCmd.AddCommand(listCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// listCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// listCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
