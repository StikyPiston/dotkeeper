package cmd

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

func ExpandPath(p string) (string, error) {
	if p == "" {
		return "", nil
	}

	p = os.ExpandEnv(p)

	if strings.HasPrefix(p, "~") {
		var home string
		var rest string

		if p == "~" || strings.HasPrefix(p, "~/") {
			u, err := user.Current()
			if err != nil {
				return "", fmt.Errorf("failed to get current user: %w", err)
			}
			home = u.HomeDir
			rest = strings.TrimPrefix(p, "~")
		} else {
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

	p = filepath.Clean(p)

	return p, nil
}
