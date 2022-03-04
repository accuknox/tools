// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Authors of KubeArmor

package cmd

import (
	"github.com/spf13/cobra"
)

// snapshotCmd represents the get command
var snapshotCmd = &cobra.Command{
	Use:   "snapshot",
	Short: "Get Snapshot Information",
	Long:  `Get Snapshot Information`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return nil
	},
}

func init() {
	rootCmd.AddCommand(snapshotCmd)
}
