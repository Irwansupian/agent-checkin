// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Minimal read interface for the SPACE ID Agent ID registry
/// (ERC-721) on BNB Chain. Holding an Agent ID is proven by
/// balanceOf(address) > 0; the token is non-transferable.
interface IAgentIdRegistry {
    function balanceOf(address owner) external view returns (uint256);
}

/// @title AgentCheckIn
/// @notice A daily presence board that only Agent ID holders can use.
///
/// Every wallet that holds a Binance Agent ID (a `.ai` name from the
/// SPACE ID Agent ID registry) may check in once per UTC day. The
/// contract records each agent's current streak, lifetime check-ins
/// and last check-in day, and keeps public counters of unique agents
/// and total check-ins. Agent ID is the access control and the
/// identity: there is no sign-up, no admin key and no fee.
///
/// The contract has no owner and no privileged functions at all:
/// nothing can be paused, minted, withdrawn or reconfigured after
/// deployment. The registry address is fixed at deployment.
contract AgentCheckIn {
    /// @notice The Agent ID registry this board gates on.
    IAgentIdRegistry public immutable registry;

    /// @notice How many distinct Agent ID wallets have ever checked in.
    uint256 public uniqueAgents;

    /// @notice How many check-ins have ever been recorded.
    uint256 public totalCheckIns;

    mapping(address => uint256) private _lastDay;
    mapping(address => uint256) private _streak;
    mapping(address => uint256) private _total;
    mapping(address => bool) private _counted;

    event CheckedIn(address indexed agent, uint256 day, uint256 streak, uint256 total);

    error NotAnAgentIdHolder();
    error AlreadyCheckedInToday();

    constructor(address registryAddress) {
        require(registryAddress != address(0), "registry is zero address");
        registry = IAgentIdRegistry(registryAddress);
    }

    /// @notice The current UTC day number, the board's clock.
    function today() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice True when `agent` holds at least one Agent ID.
    function isAgent(address agent) public view returns (bool) {
        return registry.balanceOf(agent) > 0;
    }

    /// @notice Check in for today. One check-in per agent per UTC day.
    /// A check-in on the day right after the previous one grows the
    /// streak; a gap of two or more days restarts it at 1.
    function checkIn() external {
        if (!isAgent(msg.sender)) revert NotAnAgentIdHolder();
        uint256 day = today();
        if (_lastDay[msg.sender] == day && _total[msg.sender] > 0) {
            revert AlreadyCheckedInToday();
        }
        if (_total[msg.sender] > 0 && _lastDay[msg.sender] == day - 1) {
            _streak[msg.sender] += 1;
        } else {
            _streak[msg.sender] = 1;
        }
        _lastDay[msg.sender] = day;
        _total[msg.sender] += 1;
        totalCheckIns += 1;
        if (!_counted[msg.sender]) {
            _counted[msg.sender] = true;
            uniqueAgents += 1;
        }
        emit CheckedIn(msg.sender, day, _streak[msg.sender], _total[msg.sender]);
    }

    /// @notice The agent's current streak of consecutive days.
    /// A streak whose last check-in is older than yesterday has
    /// already lapsed, so it reads as 0.
    function streakOf(address agent) external view returns (uint256) {
        if (_total[agent] == 0) return 0;
        uint256 day = today();
        if (_lastDay[agent] != day && _lastDay[agent] != day - 1) return 0;
        return _streak[agent];
    }

    /// @notice The agent's lifetime check-in count.
    function totalOf(address agent) external view returns (uint256) {
        return _total[agent];
    }

    /// @notice The UTC day number of the agent's last check-in (0 if never).
    function lastDayOf(address agent) external view returns (uint256) {
        return _lastDay[agent];
    }

    /// @notice True when the agent has already checked in today.
    function hasCheckedInToday(address agent) external view returns (bool) {
        return _total[agent] > 0 && _lastDay[agent] == today();
    }
}
