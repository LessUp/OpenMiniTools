using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

public class ErrorLogViewer
{
    private Form mainForm;
    private ComboBox logSourceComboBox;
    private ComboBox levelComboBox;
    private NumericUpDown hoursNumeric;
    private NumericUpDown maxEventsNumeric;
    private Button refreshButton;
    private Button exportButton;
    private ListView logListView;
    private SaveFileDialog saveFileDialog;

    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        
        ErrorLogViewer viewer = new ErrorLogViewer();
        viewer.InitializeComponents();
        
        Application.Run(viewer.mainForm);
    }

    private void InitializeComponents()
    {
        // Main form setup
        mainForm = new Form
        {
            Text = "错误日志查看器 (Error Log Viewer)",
            Size = new Size(900, 600),
            StartPosition = FormStartPosition.CenterScreen,
            MinimumSize = new Size(800, 500)
        };

        // Create filter panel
        Panel filterPanel = new Panel
        {
            Dock = DockStyle.Top,
            Height = 70,
            Padding = new Padding(10)
        };

        // Log source selection
        Label logSourceLabel = new Label
        {
            Text = "日志源:",
            AutoSize = true,
            Location = new Point(10, 15)
        };

        logSourceComboBox = new ComboBox
        {
            Location = new Point(80, 12),
            Width = 120,
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        
        string[] logSources = { "System", "Application", "Security", "Setup", "Windows PowerShell" };
        logSourceComboBox.Items.AddRange(logSources);
        logSourceComboBox.SelectedIndex = 0;

        // Level selection
        Label levelLabel = new Label
        {
            Text = "级别:",
            AutoSize = true,
            Location = new Point(220, 15)
        };

        levelComboBox = new ComboBox
        {
            Location = new Point(270, 12),
            Width = 120,
            DropDownStyle = ComboBoxStyle.DropDownList
        };
        
        string[] levels = { "Error", "Warning", "Information", "All" };
        levelComboBox.Items.AddRange(levels);
        levelComboBox.SelectedIndex = 0;

        // Hours back selection
        Label hoursLabel = new Label
        {
            Text = "过去的小时数:",
            AutoSize = true,
            Location = new Point(410, 15)
        };

        hoursNumeric = new NumericUpDown
        {
            Location = new Point(520, 12),
            Width = 60,
            Minimum = 1,
            Maximum = 720,
            Value = 24
        };

        // Max events
        Label maxEventsLabel = new Label
        {
            Text = "最大事件数:",
            AutoSize = true,
            Location = new Point(600, 15)
        };

        maxEventsNumeric = new NumericUpDown
        {
            Location = new Point(690, 12),
            Width = 60,
            Minimum = 1,
            Maximum = 1000,
            Value = 50
        };

        // Refresh button
        refreshButton = new Button
        {
            Text = "刷新",
            Location = new Point(770, 10),
            Width = 100,
            Height = 30
        };
        refreshButton.Click += RefreshButton_Click;

        // Export button
        exportButton = new Button
        {
            Text = "导出",
            Location = new Point(770, 40),
            Width = 100,
            Height = 30
        };
        exportButton.Click += ExportButton_Click;

        // Add controls to filter panel
        filterPanel.Controls.AddRange(new Control[]
        {
            logSourceLabel, logSourceComboBox,
            levelLabel, levelComboBox,
            hoursLabel, hoursNumeric,
            maxEventsLabel, maxEventsNumeric,
            refreshButton, exportButton
        });

        // Create log list view
        logListView = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true,
            GridLines = true,
            MultiSelect = false,
            HideSelection = false
        };

        // Add columns
        logListView.Columns.Add("时间", 150);
        logListView.Columns.Add("级别", 80);
        logListView.Columns.Add("源", 150);
        logListView.Columns.Add("ID", 80);
        logListView.Columns.Add("消息", 400);

        // Create save file dialog
        saveFileDialog = new SaveFileDialog
        {
            Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*",
            Title = "导出日志",
            FileName = "ErrorLog.csv"
        };

        // Add controls to form
        mainForm.Controls.Add(logListView);
        mainForm.Controls.Add(filterPanel);

        // Initialize with data
        LoadEventLog();
    }

    private void RefreshButton_Click(object sender, EventArgs e)
    {
        LoadEventLog();
    }

    private void ExportButton_Click(object sender, EventArgs e)
    {
        if (logListView.Items.Count == 0)
        {
            MessageBox.Show("没有可导出的日志", "导出", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        if (saveFileDialog.ShowDialog() == DialogResult.OK)
        {
            try
            {
                using (var writer = new System.IO.StreamWriter(saveFileDialog.FileName, false, System.Text.Encoding.UTF8))
                {
                    // Write header
                    writer.WriteLine("\"Time\",\"Level\",\"Source\",\"EventID\",\"Message\"");

                    // Write data
                    foreach (ListViewItem item in logListView.Items)
                    {
                        string line = string.Join(",", item.SubItems.Cast<ListViewItem.ListViewSubItem>()
                            .Select(subItem => $"\"{EscapeCsvField(subItem.Text)}\""));
                        writer.WriteLine(line);
                    }
                }

                MessageBox.Show(string.Format("已成功导出到: {0}", saveFileDialog.FileName), "导出", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show(string.Format("导出失败: {0}", ex.Message), "错误", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    private string EscapeCsvField(string field)
    {
        if (string.IsNullOrEmpty(field))
            return string.Empty;
        
        return field.Replace("\"", "\"\"");
    }

    private void LoadEventLog()
    {
        logListView.Items.Clear();
        Cursor.Current = Cursors.WaitCursor;
        refreshButton.Enabled = false;

        try
        {
            string logName = logSourceComboBox.SelectedItem.ToString();
            string levelName = levelComboBox.SelectedItem.ToString();
            int hoursBack = (int)hoursNumeric.Value;
            int maxEvents = (int)maxEventsNumeric.Value;

            // Create event log query
            EventLog eventLog = new EventLog(logName);
            
            // Get events
            var entries = eventLog.Entries.Cast<EventLogEntry>()
                .Where(entry => (DateTime.Now - entry.TimeGenerated).TotalHours <= hoursBack)
                .Where(entry => FilterByLevel(entry, levelName))
                .OrderByDescending(entry => entry.TimeGenerated)
                .Take(maxEvents)
                .ToList();

            // Populate list view
            foreach (var entry in entries)
            {
                ListViewItem item = new ListViewItem(entry.TimeGenerated.ToString());

                // Add level
                string level = GetLevelString(entry.EntryType);
                item.SubItems.Add(level);

                // Add color based on level
                switch (entry.EntryType)
                {
                    case EventLogEntryType.Error:
                        item.ForeColor = Color.DarkRed;
                        break;
                    case EventLogEntryType.Warning:
                        item.ForeColor = Color.DarkOrange;
                        break;
                    case EventLogEntryType.Information:
                        item.ForeColor = Color.DarkGreen;
                        break;
                }

                // Add remaining data
                item.SubItems.Add(entry.Source);
                item.SubItems.Add(entry.EventID.ToString());
                
                // Truncate message if too long
                string message = entry.Message ?? "";
                if (message.Length > 500)
                {
                    message = message.Substring(0, 497) + "...";
                }
                
                // Replace line breaks for display
                message = message.Replace("\r\n", " ").Replace("\n", " ");
                item.SubItems.Add(message);
                
                // Add to list
                logListView.Items.Add(item);
            }

            // Update status
            mainForm.Text = string.Format("错误日志查看器 - {0} 条事件 (从 {1})", entries.Count, logName);
            
            if (entries.Count == 0)
            {
                MessageBox.Show(string.Format("在指定的时间范围内没有找到{0}级别的事件日志", levelName), 
                    "无结果", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(string.Format("加载事件日志时出错: {0}", ex.Message), "错误", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            refreshButton.Enabled = true;
            Cursor.Current = Cursors.Default;
        }
    }

    private bool FilterByLevel(EventLogEntry entry, string levelName)
    {
        if (levelName == "All")
            return true;
            
        switch (levelName)
        {
            case "Error":
                return entry.EntryType == EventLogEntryType.Error;
            case "Warning":
                return entry.EntryType == EventLogEntryType.Warning;
            case "Information":
                return entry.EntryType == EventLogEntryType.Information;
            default:
                return true;
        }
    }

    private string GetLevelString(EventLogEntryType entryType)
    {
        switch (entryType)
        {
            case EventLogEntryType.Error:
                return "错误";
            case EventLogEntryType.Warning:
                return "警告";
            case EventLogEntryType.Information:
                return "信息";
            case EventLogEntryType.SuccessAudit:
                return "成功审核";
            case EventLogEntryType.FailureAudit:
                return "失败审核";
            default:
                return entryType.ToString();
        }
    }
}
