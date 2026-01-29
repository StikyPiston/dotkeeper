package cmd

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

// ExpandPath expands environment variables and ~ in paths.
// Supports:
//   - $VAR and ${VAR}
//   - ~ and ~/
//   - ~username/
//
// It does NOT check whether the path exists.
func ExpandPath(p string) (string, error) {
	if p == "" {
		return "", nil
	}

	// 1. Expand environment variables ($HOME, $XDG_*, etc.)
	p = os.ExpandEnv(p)

	// 2. Expand ~
	if strings.HasPrefix(p, "~") {
		var home string
		var rest string

		if p == "~" || strings.HasPrefix(p, "~/") {
			// Current user
			u, err := user.Current()
			if err != nil {
				return "", fmt.Errorf("failed to get current user: %w", err)
			}
			home = u.HomeDir
			rest = strings.TrimPrefix(p, "~")
		} else {
			// ~username
			slash := strings.IndexRune(p, '/')
			var username string
			if slash == -1 {
				username = p[1:]
				rest = ""
			} else {
				username = p[1:slash]
				rest = p[slash:]
			}

			u, err := user.Lookup(username)
			if err != nil {
				return "", fmt.Errorf("failed to lookup user %q: %w", username, err)
			}
			home = u.HomeDir
		}

		p = filepath.Join(home, rest)
	}

	// 3. Clean up path (remove //, ./, etc.)
	p = filepath.Clean(p)

	return p, nil
}
