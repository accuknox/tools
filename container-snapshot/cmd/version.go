// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Authors of KubeArmor

package cmd

import (
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
)

var GitCommit string
var GitBranch string
var BuildDate string
var Version string

// versionCmd represents the get command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Display version information",
	Long:  `Display version information`,
	RunE: func(cmd *cobra.Command, args []string) error {
		log.Info().Msgf("commit:%v, branch: %v, date: %v, version: %v",
			GitCommit, GitBranch, BuildDate, Version)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
