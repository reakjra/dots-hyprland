import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("System prompt")
            text: Config.options.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.ai.systemPrompt = text;
                });
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        ConfigSpinBox {
            icon: "timer_off"
            text: Translation.tr("Total duration timeout (s)")
            value: Config.options.musicRecognition.timeout
            from: 10
            to: 100
            stepSize: 2
            onValueChanged: {
                Config.options.musicRecognition.timeout = value;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (s)")
            value: Config.options.musicRecognition.interval
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.musicRecognition.interval = value;
            }
        }
    }

    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("User agent (for services that require it)")
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Resources")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }

        ConfigSpinBox {
            icon: "chart_data"
            text: Translation.tr("History length (data points)")
            value: Config.options.resources.historyLength
            from: 10
            to: 300
            stepSize: 10
            onValueChanged: {
                Config.options.resources.historyLength = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Enable monitoring")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("CPU")
                    checked: Config.options.resources.enableCpu
                    onCheckedChanged: {
                        Config.options.resources.enableCpu = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "deployed_code"
                    text: Translation.tr("RAM")
                    checked: Config.options.resources.enableRam
                    onCheckedChanged: {
                        Config.options.resources.enableRam = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Swap")
                    checked: Config.options.resources.enableSwap
                    onCheckedChanged: {
                        Config.options.resources.enableSwap = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "airwave"
                    text: Translation.tr("GPU")
                    checked: Config.options.resources.enableGpu
                    onCheckedChanged: {
                        Config.options.resources.enableGpu = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("GPU Configuration")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("dGPU card (e.g., card0, leave empty for auto)")
                    text: Config.options.resources.gpu.dgpuCard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.resources.gpu.dgpuCard = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("dGPU name override (leave empty for auto)")
                    text: Config.options.resources.gpu.dgpuName
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.resources.gpu.dgpuName = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("iGPU card (e.g., card1, leave empty for auto)")
                    text: Config.options.resources.gpu.igpuCard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.resources.gpu.igpuCard = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("iGPU name override (leave empty for auto)")
                    text: Config.options.resources.gpu.igpuName
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.resources.gpu.igpuName = text;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Overlay GPU Display")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Show dGPU")
                    checked: Config.options.resources.gpu.overlay.showDGpu
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.showDGpu = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("Show iGPU")
                    checked: Config.options.resources.gpu.overlay.showIGpu
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.showIGpu = checked;
                    }
                }
            }

            ContentSubsectionLabel {
                text: Translation.tr("dGPU metrics")
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("Usage")
                    checked: Config.options.resources.gpu.overlay.dGpu.showUsage
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showUsage = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("VRAM")
                    checked: Config.options.resources.gpu.overlay.dGpu.showVram
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showVram = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Temp")
                    checked: Config.options.resources.gpu.overlay.dGpu.showTemp
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showTemp = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "air"
                    text: Translation.tr("Fan")
                    checked: Config.options.resources.gpu.overlay.dGpu.showFan
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showFan = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "bolt"
                    text: Translation.tr("Power")
                    checked: Config.options.resources.gpu.overlay.dGpu.showPower
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showPower = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "local_fire_department"
                    text: Translation.tr("Temp Junction")
                    checked: Config.options.resources.gpu.overlay.dGpu.showTempJunction
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showTempJunction = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory_alt"
                    text: Translation.tr("Temp Memory")
                    checked: Config.options.resources.gpu.overlay.dGpu.showTempMem
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.dGpu.showTempMem = checked;
                    }
                }
            }

            ContentSubsectionLabel {
                text: Translation.tr("iGPU metrics")
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("Usage")
                    checked: Config.options.resources.gpu.overlay.iGpu.showUsage
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.iGpu.showUsage = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("VRAM")
                    checked: Config.options.resources.gpu.overlay.iGpu.showVram
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.iGpu.showVram = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Temp")
                    checked: Config.options.resources.gpu.overlay.iGpu.showTemp
                    onCheckedChanged: {
                        Config.options.resources.gpu.overlay.iGpu.showTemp = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Bar Popup GPU Display")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Show dGPU")
                    checked: Config.options.resources.gpu.bar.showDGpu
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.showDGpu = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("Show iGPU")
                    checked: Config.options.resources.gpu.bar.showIGpu
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.showIGpu = checked;
                    }
                }
            }

            ContentSubsectionLabel {
                text: Translation.tr("dGPU metrics")
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("Usage")
                    checked: Config.options.resources.gpu.bar.dGpu.showUsage
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.dGpu.showUsage = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("VRAM")
                    checked: Config.options.resources.gpu.bar.dGpu.showVram
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.dGpu.showVram = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Temp")
                    checked: Config.options.resources.gpu.bar.dGpu.showTemp
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.dGpu.showTemp = checked;
                    }
                }
            }

            ContentSubsectionLabel {
                text: Translation.tr("iGPU metrics")
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("Usage")
                    checked: Config.options.resources.gpu.bar.iGpu.showUsage
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.iGpu.showUsage = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("VRAM")
                    checked: Config.options.resources.gpu.bar.iGpu.showVram
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.iGpu.showVram = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "device_thermostat"
                    text: Translation.tr("Temp")
                    checked: Config.options.resources.gpu.bar.iGpu.showTemp
                    onCheckedChanged: {
                        Config.options.resources.gpu.bar.iGpu.showTemp = checked;
                    }
                }
            }
        }

    }

    ContentSection {
        icon: "file_open"
        title: Translation.tr("Save paths")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Video Recording Path")
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
        }
    }

    ContentSection {
        icon: "search"
        title: Translation.tr("Search")

        ConfigSwitch {
            text: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
            }
        }

        ContentSubsection {
            title: Translation.tr("Prefixes")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Action")
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.action = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Clipboard")
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.clipboard = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Emojis")
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.emojis = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Math")
                    text: Config.options.search.prefix.math
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.math = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Shell command")
                    text: Config.options.search.prefix.shellCommand
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.shellCommand = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Web search")
                    text: Config.options.search.prefix.webSearch
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.webSearch = text;
                    }
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Web search")
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Base URL")
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text;
                }
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")
        ConfigRow {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "thermometer"
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }
        }
        
        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("City name")
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (m)")
            value: Config.options.bar.weather.fetchInterval
            from: 5
            to: 50
            stepSize: 5
            onValueChanged: {
                Config.options.bar.weather.fetchInterval = value;
            }
        }
    }
}
