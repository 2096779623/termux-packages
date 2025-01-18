//go:build android

package main

import (
	"fmt"
	"os"

	"github.com/rs/zerolog"
	"github.com/urfave/cli/v2"

	"github.com/cloudflare/cloudflared/cmd/cloudflared/cliutil"
	"github.com/cloudflare/cloudflared/cmd/cloudflared/tunnel"
	"github.com/cloudflare/cloudflared/config"
	"github.com/cloudflare/cloudflared/logger"
)

var termuxprefix string = os.Getenv("PREFIX")

func runApp(app *cli.App, graceShutdownC chan struct{}) {

	app.Commands = append(app.Commands, &cli.Command{
		Name:  "service",
		Usage: "Manages the cloudflared system service",
		Subcommands: []*cli.Command{
			{
				Name:   "install",
				Usage:  "Install cloudflared as a system service",
				Action: cliutil.ConfiguredAction(installAndroidService),
				Flags: []cli.Flag{
					noUpdateServiceFlag,
				},
			},
			{
				Name:   "uninstall",
				Usage:  "Uninstall the cloudflared service",
				Action: cliutil.ConfiguredAction(uninstallAndroidService),
			},
		},
	})
	app.Run(os.Args)
}

// The directory and files that are used by the service.
// These are hard-coded in the templates below.
const (
	serviceConfigFile        = "config.yml"
	serviceCredentialFile    = "cert.pem"
	cloudflaredService       = "cloudflared.service"
	cloudflaredUpdateService = "cloudflared-update.service"
	cloudflaredUpdateTimer   = "cloudflared-update.timer"
)

var (
	serviceConfigDir    = termuxprefix + "/etc/cloudflared"
	serviceConfigPath   = serviceConfigDir + "/" + serviceConfigFile
	noUpdateServiceFlag = &cli.BoolFlag{
		Name:  "no-update-service",
		Usage: "Disable auto-update of the cloudflared linux service, which restarts the server to upgrade for new versions.",
		Value: false,
	}
)

var termuxTemplate = ServiceTemplate{
	Path:     termuxprefix + "/var/service/cloudflared/run",
	FileMode: 0755,
	Content: `#!/` + termuxprefix + `/bin/sh
{{.Path}} {{ range .ExtraArgs }} {{ . }}{{ end }}
`,
}

func installAndroidService(c *cli.Context) error {
	log := logger.CreateLoggerFromContext(c, logger.EnableTerminalLog)

	etPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("error determining executable path: %v", err)
	}
	templateArgs := ServiceTemplateArgs{
		Path: etPath,
	}

	// Check if the "no update flag" is set
	autoUpdate := !c.IsSet(noUpdateServiceFlag.Name)

	var extraArgsFunc func(c *cli.Context, log *zerolog.Logger) ([]string, error)
	if c.NArg() == 0 {
		extraArgsFunc = buildArgsForConfig
	} else {
		extraArgsFunc = buildArgsForToken
	}

	extraArgs, err := extraArgsFunc(c, log)
	if err != nil {
		return err
	}

	templateArgs.ExtraArgs = extraArgs

	log.Info().Msgf("Using termux-services")
	err = installTermuxService(&templateArgs, autoUpdate, log)

	if err == nil {
		log.Info().Msg("Android service for cloudflared installed successfully")
	}
	return err
}

func buildArgsForConfig(c *cli.Context, log *zerolog.Logger) ([]string, error) {
	if err := ensureConfigDirExists(serviceConfigDir); err != nil {
		return nil, err
	}

	src, _, err := config.ReadConfigFile(c, log)
	if err != nil {
		return nil, err
	}

	// can't use context because this command doesn't define "credentials-file" flag
	configPresent := func(s string) bool {
		val, err := src.String(s)
		return err == nil && val != ""
	}
	if src.TunnelID == "" || !configPresent(tunnel.CredFileFlag) {
		return nil, fmt.Errorf(`Configuration file %s must contain entries for the tunnel to run and its associated credentials:
tunnel: TUNNEL-UUID
credentials-file: CREDENTIALS-FILE
`, src.Source())
	}
	if src.Source() != serviceConfigPath {
		if exists, err := config.FileExists(serviceConfigPath); err != nil || exists {
			return nil, fmt.Errorf("Possible conflicting configuration in %[1]s and %[2]s. Either remove %[2]s or run `cloudflared --config %[2]s service install`", src.Source(), serviceConfigPath)
		}

		if err := copyFile(src.Source(), serviceConfigPath); err != nil {
			return nil, fmt.Errorf("failed to copy %s to %s: %w", src.Source(), serviceConfigPath, err)
		}
	}

	return []string{
		"--config", termuxprefix + "/etc/cloudflared/config.yml", "tunnel", "run",
	}, nil
}

func installTermuxService(templateArgs *ServiceTemplateArgs, autoUpdate bool, log *zerolog.Logger) error {
	if autoUpdate {
		templateArgs.ExtraArgs = append([]string{"--autoupdate-freq 24h0m0s"}, templateArgs.ExtraArgs...)
	} else {
		templateArgs.ExtraArgs = append([]string{"--no-autoupdate"}, templateArgs.ExtraArgs...)
	}

	if err := termuxTemplate.Generate(templateArgs); err != nil {
		log.Err(err).Msg("error generating system template")
		return err
	}

	return runCommand("sv", "up", "cloudflared")
}

func uninstallAndroidService(c *cli.Context) error {
	log := logger.CreateLoggerFromContext(c, logger.EnableTerminalLog)

	var err error
	log.Info().Msg("Using termux-services")
	err = uninstallTermuxServices(log)

	if err == nil {
		log.Info().Msg("Android service for cloudflared uninstalled successfully")
	}
	return err
}

func uninstallTermuxServices(log *zerolog.Logger) error {
	if err := runCommand("sv", "down", "cloudflared"); err != nil {
		log.Err(err).Msg("sv down cloudflared error")
		return err
	}
	if err := os.RemoveAll(termuxprefix + "/var/service/cloudflared"); err != nil {
		log.Err(err).Msg("error removing service")
		return err
	}
	return nil
}
