package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

func LoadState() (State, error) {
	var st State
	home, err := os.UserHomeDir()
	if err != nil {
		return st, fmt.Errorf(" Failed to get home directory: %w", err)
	}

	statePath := filepath.Join(home, ".dotkeeper-state.json")

	data, err := os.ReadFile(statePath)
	if err != nil {
		if os.IsNotExist(err) {
			// Return empty state if file doesn't exist
			return State{}, nil
		}
		return st, fmt.Errorf(" Failed to read state file: %w", err)
	}

	if err := json.Unmarshal(data, &st); err != nil {
		return st, fmt.Errorf(" Failed to parse state file: %w", err)
	}

	return st, nil
}

func DeactivateKeep() error {
	st, err := LoadState()
	if err != nil {
		return err
	}

	if len(st.Links) == 0 {
		fmt.Println(" No active keep to deactivate.")
		return nil
	}

	for _, link := range st.Links {
		dest, err := ExpandPath(link.Target)
		if err != nil {
			fmt.Printf(" Cannot expand %s: %v\n", link.Target, err)
			continue
		}

		if fi, err := os.Lstat(dest); err == nil {
			if fi.Mode()&os.ModeSymlink != 0 || fi.Mode().IsRegular() {
				if err := os.Remove(dest); err != nil {
					fmt.Printf(" Cannot remove %s: %v\n", dest, err)
				} else {
					fmt.Printf(" Removed: %s\n", dest)
				}
			} else {
				fmt.Printf("󰒭 Skipping non-symlink: %s\n", dest)
			}
		}
	}

	// Save empty state
	home, err := os.UserHomeDir()
	statePath := filepath.Join(home, ".dotkeeper-state.json")

	if err := SaveState(statePath, State{}); err != nil {
		return fmt.Errorf(" Failed to write empty state: %w", err)
	}

	fmt.Println(" Deactivated keep")
	return nil
}

// deactivateCmd represents the deactivate command
var deactivateCmd = &cobra.Command{
	Use:   "deactivate",
	Short: "Deactivates the current keep",
	Run: func(cmd *cobra.Command, args []string) {
		DeactivateKeep()
	},
}

func init() {
	rootCmd.AddCommand(deactivateCmd)
}
