local grafonnet = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = grafonnet.dashboard;
local datasource = dashboard.variable.datasource;
{
  grafanaDashboards+:: {

    local datasourceVariable =
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source'),

    local targetVariable =
      dashboard.variable.query.new(
        name='target',
        query='label_values(ifNumber, target)',
      ) +

      dashboard.variable.query.withDatasourceFromVariable(datasourceVariable) +
      dashboard.variable.query.withSort(1) +
      dashboard.variable.query.generalOptions.withLabel('Target') +
      //      dashboard.variable.query.selectionOptions.withMulti(true) +
      //      dashboard.variable.query.selectionOptions.withIncludeAll(true) +
      dashboard.variable.query.refresh.onLoad() +
      dashboard.variable.query.refresh.onTime(),

    local interfaceSelector =
      dashboard.variable.query.new(
        name='interfaceSelector',
      ) +

      dashboard.variable.query.withDatasourceFromVariable(datasourceVariable) +
      dashboard.variable.query.withSort(1) +
      dashboard.variable.query.generalOptions.withLabel('interfaceSelector') +
      dashboard.variable.query.withRegex('/.*interfaceSelector="([^"]*).*/') +
      dashboard.variable.query.selectionOptions.withMulti(true) +
      dashboard.variable.query.selectionOptions.withIncludeAll(true) +
      dashboard.variable.query.refresh.onLoad() +
      dashboard.variable.query.refresh.onTime() +
        {
          local query = |||
              query_result(group(label_replace(ifHCInOctet{target=~"$target"}, "interfaceSelector", "$1", "ifName", "(.*)") or label_replace(ifHCInOctet{target=~"$target"}, "interfaceSelector", "$1", "ifAlias", "(.*)")) by (interfaceSelector))
            |||,
          query: query,
        },

    local targets = grafonnet.panel.stat.new('Targets') +
                    grafonnet.panel.stat.queryOptions.withTargets([
                      grafonnet.query.prometheus.new(
                        '$datasource',
                        'count(sum by (target) (snmp_scrape_packets_sent{module="%s"}))' % $._config.module,
                      ),
                    ]) +
                    grafonnet.panel.stat.standardOptions.withUnit('none'),

    local pdus =
      grafonnet.panel.stat.new('Metrics scraped total') +
      grafonnet.panel.stat.queryOptions.withTargets([
        grafonnet.query.prometheus.new(
          '$datasource',
          'sum(snmp_scrape_pdus_returned{module="%s"})' % $._config.module,
        ),
      ]) +
      grafonnet.panel.stat.standardOptions.withUnit('none'),


    local uptime = grafonnet.panel.stat.new('Uptime') +
                   grafonnet.panel.stat.queryOptions.withTargets([
                     grafonnet.query.prometheus.new(
                       '$datasource',
                       'sum by (target) (sysUpTime{target=~"$target"} / 100)'
                     ),
                   ]) +
                   grafonnet.panel.stat.standardOptions.withUnit('s'),


    local ifNumberStatPanel(selector) =
      grafonnet.panel.stat.new(
        'Nember of interfaces',
      ) +
      grafonnet.panel.stat.queryOptions.withTargets(
        grafonnet.query.prometheus.new(
          '$datasource',
          |||
            sum by (target) (ifNumber{%s})
          ||| % selector,
        ) +
        grafonnet.query.prometheus.withLegendFormat(
          '{{target}}'
        ),
      ) +
      grafonnet.panel.stat.options.withTextMode('value_and_name') +
      grafonnet.panel.stat.standardOptions.withUnit('none') +
      grafonnet.panel.stat.queryOptions.withMaxDataPoints(100) +
      grafonnet.panel.stat.standardOptions.withMappings(
        grafonnet.panel.stat.standardOptions.mapping.ValueMap.withType('value') +
        grafonnet.panel.stat.standardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'Down', color: 'red' },
            '1': { text: 'Up', color: 'green' },
          }
        )
      ) +
      grafonnet.panel.stat.standardOptions.withLinks([
        grafonnet.panel.stat.panelOptions.link.withTitle('Go To Traffic') +
        grafonnet.panel.stat.panelOptions.link.withType('link') +
        grafonnet.panel.stat.panelOptions.link.withUrl(
          'd/snmp-exporter-ifmib-traffic-w2s9a8c/snmp-if-mib-traffic?var-target=${__field.labels.target}',
        ),
      ]) +
      grafonnet.panel.stat.standardOptions.thresholds.withSteps([
        grafonnet.panel.stat.standardOptions.threshold.step.withValue(0.0) +
        grafonnet.panel.stat.standardOptions.threshold.step.withColor('red'),
        grafonnet.panel.stat.standardOptions.threshold.step.withValue(0.001) +
        grafonnet.panel.stat.standardOptions.threshold.step.withColor('green'),
      ]),


    local scrapeDurationStatPanel =
      grafonnet.panel.stat.new(
        'Scrape duration',
      ) +
      grafonnet.panel.stat.queryOptions.withTargets(
        grafonnet.query.prometheus.new(
          '$datasource',
          |||
            sum by (target) (snmp_scrape_duration_seconds{module="%s"})
          ||| % $._config.module,
        ) +
        grafonnet.query.prometheus.withLegendFormat(
          '{{target}}'
        ),
      ) +
      grafonnet.panel.stat.options.withTextMode('value_and_name') +
      grafonnet.panel.stat.standardOptions.withUnit('seconds') +
      grafonnet.panel.stat.queryOptions.withMaxDataPoints(100) +
      grafonnet.panel.stat.standardOptions.withMappings(
        grafonnet.panel.stat.standardOptions.mapping.ValueMap.withType('value') +
        grafonnet.panel.stat.standardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'Down', color: 'red' },
            '1': { text: 'Up', color: 'green' },
          }
        )
      ) +
      grafonnet.panel.stat.standardOptions.withLinks([
        grafonnet.panel.stat.panelOptions.link.withTitle('Go To Traffic') +
        grafonnet.panel.stat.panelOptions.link.withType('link') +
        grafonnet.panel.stat.panelOptions.link.withUrl(
          'd/snmp-exporter-ifmib-traffic-w2s9a8c/snmp-if-mib-traffic?var-target=${__field.labels.target}',
        ),
      ]) +
      grafonnet.panel.stat.standardOptions.thresholds.withSteps([
        grafonnet.panel.stat.standardOptions.threshold.step.withValue(0.0) +
        grafonnet.panel.stat.standardOptions.threshold.step.withColor('red'),
        grafonnet.panel.stat.standardOptions.threshold.step.withValue(0.001) +
        grafonnet.panel.stat.standardOptions.threshold.step.withColor('green'),
      ]),

    local traffic = grafonnet.panel.row.new('Traffic $interfaceSelector') +
                    grafonnet.panel.row.withRepeat('interfaceSelector') +
                    grafonnet.panel.row.withPanels([


                    grafonnet.panel.timeSeries.new(
                      'Traffic',
                    ) +
                    grafonnet.panel.timeSeries.queryOptions.withTargets(
                      [
                        grafonnet.query.prometheus.new(
                          '$datasource',
                          |||
                            max by (target) (
                              rate(ifHCInOctets{ifAlias=~"$interfaceSelector", target=~"$target"}[$__rate_interval]) or
                              rate(ifHCInOctets{ifName=~"$interfaceSelector", target=~"$target"}[$__rate_interval])
                              ) * 8
                          |||,
                        ) +
                        grafonnet.query.prometheus.withLegendFormat(
                          'Inbound'
                        ),
                        grafonnet.query.prometheus.new(
                          '$datasource',
                          |||
                            max by (target) (
                              rate(ifHCOutOctets{ifAlias=~"$interfaceSelector", target=~"$target"}[$__rate_interval]) or
                              rate(ifHCOutOctets{ifName=~"$interfaceSelector", target=~"$target"}[$__rate_interval])
                              ) * 8
                          |||,
                        ) +
                        grafonnet.query.prometheus.withLegendFormat(
                          'Outbound'
                        ),
                      ]
                    ) +
                    grafonnet.panel.timeSeries.standardOptions.withUnit('binbps') +
                    grafonnet.panel.timeSeries.options.tooltip.withMode('multi') +
                    grafonnet.panel.timeSeries.options.tooltip.withSort('desc')
                    ]),


    'snmp_exporter_if_mib_overview.json':
      dashboard.new(
        'SNMP if_mib Overview'
      ) +
      dashboard.withVariables(datasourceVariable) +
      dashboard.withPanels(
        grafonnet.util.grid.makeGrid([targets, pdus], panelWidth=12, panelHeight=4, startY=0) +
        grafonnet.util.grid.makeGrid([ifNumberStatPanel('')], panelWidth=24, panelHeight=4, startY=4) +
        grafonnet.util.grid.makeGrid([scrapeDurationStatPanel], panelWidth=24, panelHeight=4, startY=8)
      ) +
      dashboard.withUid('snmp-exporter-ifmib-overview-x9rrb4a') +
      dashboard.withTimezone($._config.timezone),


    'snmp_exporter_if_mib_traffic.json':
      dashboard.new(
        'SNMP if_mib Traffic'
      ) +
      dashboard.withVariables([datasourceVariable, targetVariable, interfaceSelector]) +
      dashboard.withPanels(
        grafonnet.util.grid.makeGrid([uptime, ifNumberStatPanel('target=~"$target"')], panelWidth=12, panelHeight=4, startY=0) +
        grafonnet.util.grid.makeGrid([traffic], panelWidth=24, panelHeight=8, startY=4)
      ) +
      dashboard.withUid('snmp-exporter-ifmib-traffic-w2s9a8c') +
      dashboard.withTimezone($._config.timezone) +
      dashboard.withLinks([
        dashboard.link.link.new('Summary', 'd/snmp-exporter-ifmib-overview-x9rrb4a/snmp-if-mib-overview'),
      ]),
  },
}
