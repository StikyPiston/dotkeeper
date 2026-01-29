package cmd

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/fatih/color"
)

func CreateSymlink(keepName, src, dest string) error {
	homeDir, err := os.UserHomeDir()
	keepsDir := filepath.Join(homeDir, ".dotkeep", keepName)
	expandedSrc, err := ExpandPath(src)
	src = filepath.Join(keepsDir, expandedSrc)
	dest, err = ExpandPath(dest)
	if err != nil {
		return err
	}

	if err := os.Symlink(src, dest); err != nil {
		return fmt.Errorf(" Failed to create symlink %s -> %s: %w", src, dest, err)
	}

	return nil
}

var activateCmd = &cobra.Command{
	Use:   "activate",
	Short: "Activate a keep",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		keep := args[0]

		home, err := os.UserHomeDir()
		if err != nil {
			log.Fatal(err)
			return
		}

		DeactivateKeep()

		keepDir := filepath.Join(home, ".dotkeep", keep)
		links, err := LoadKeep(keepDir)
		if err != nil {
			log.Fatal(err)
			return
		}

		for _, link := range links {
			if err := CreateSymlink(keep, link.Source, link.Target); err != nil {
				color.Red(" Error creating symlink: %s -> %s\n", link.Target, link.Source)
			} else {
				color.Blue(" Symlinked %s -> %s\n", link.Target, link.Source)
			}
		}

		stateFile := filepath.Join(home, ".dotkeeper-state.json")

		st := State{
			Keep: keep,
			Links: links,
		}

		if err := SaveState(stateFile, st); err != nil {
			log.Fatal(" Failed to write state file: %s", err)
		}

		color.Green(" Activated keep: %s\n", keep)
	},
}

func init() {
	rootCmd.AddCommand(activateCmd)
}
