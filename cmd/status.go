package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// statusCmd represents the status command
var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "See the currently active keep",
	Long:  "Usage: dotkeeper status",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("status called")
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
