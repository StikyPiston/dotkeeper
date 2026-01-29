package cmd

type State struct {
	Keep  string `json:"keep"`
	Links []Link `json:"links"`
}

type Keep struct {
	Links []Link `json:"links"`
}

type Link struct {
	Source string `json:"source"`
	Target string `json:"target"`
}
