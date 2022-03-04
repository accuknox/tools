// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Authors of KubeArmor

package cmd

import (
	"github.com/kubearmor/kubearmor-client/k8s"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
)

var client *k8s.Client

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		var err error

		client, err = k8s.ConnectK8sClient()
		if err != nil {
			log.Error().Msgf("unable to create Kubernetes clients: %s", err.Error())
			return err
		}
		_ = client
		return nil
	},
	Use:   "container-snapshot",
	Short: "Get container snapshot",
	Long: `Get container snapshot
	
Container snapshot gets the details of all the executable files, SUID files and other files and keeps the snapshot for later verification.
	`,
	SilenceUsage:  true,
	SilenceErrors: true,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}
