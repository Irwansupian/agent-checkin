// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AgentCheckIn} from "../contracts/AgentCheckIn.sol";

/// @notice Stand-in for the Agent ID registry: an address "holds an
/// Agent ID" exactly when the test says it does.
contract MockRegistry {
    mapping(address => uint256) private _balances;

    function setBalance(address who, uint256 amount) external {
        _balances[who] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}

/// @notice Minimal hand-rolled test harness (no external libraries):
/// each test is a function that reverts on failure.
contract AgentCheckInTest {
    MockRegistry internal registry;
    AgentCheckIn internal board;
    address internal agent = address(0xA6E17);
    address internal stranger = address(0x57A9);

    function setUp() public {
        registry = new MockRegistry();
        board = new AgentCheckIn(address(registry));
        registry.setBalance(agent, 1);
    }

    function _warpToDay(uint256 day, uint256 plusSeconds) internal {
        // Foundry cheatcode address.
        (bool ok,) = address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D).call(
            abi.encodeWithSignature("warp(uint256)", day * 1 days + plusSeconds)
        );
        require(ok, "warp failed");
    }

    function _prank(address who) internal {
        (bool ok,) = address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D).call(
            abi.encodeWithSignature("prank(address)", who)
        );
        require(ok, "prank failed");
    }

    function testStrangerCannotCheckIn() public {
        setUp();
        _prank(stranger);
        (bool ok,) = address(board).call(abi.encodeWithSignature("checkIn()"));
        require(!ok, "stranger check-in should revert");
        require(board.totalCheckIns() == 0, "no check-in should be recorded");
    }

    function testFirstCheckIn() public {
        setUp();
        _warpToDay(20000, 3600);
        _prank(agent);
        board.checkIn();
        require(board.streakOf(agent) == 1, "streak should be 1");
        require(board.totalOf(agent) == 1, "total should be 1");
        require(board.uniqueAgents() == 1, "one unique agent");
        require(board.totalCheckIns() == 1, "one total check-in");
        require(board.hasCheckedInToday(agent), "should read as checked in");
    }

    function testSecondCheckInSameDayReverts() public {
        setUp();
        _warpToDay(20000, 3600);
        _prank(agent);
        board.checkIn();
        _prank(agent);
        (bool ok,) = address(board).call(abi.encodeWithSignature("checkIn()"));
        require(!ok, "second check-in on the same day should revert");
        require(board.totalOf(agent) == 1, "total should stay 1");
    }

    function testStreakGrowsThenLapses() public {
        setUp();
        _warpToDay(20000, 100);
        _prank(agent);
        board.checkIn();
        _warpToDay(20001, 100);
        _prank(agent);
        board.checkIn();
        require(board.streakOf(agent) == 2, "streak should be 2 on day two");
        _warpToDay(20003, 100);
        require(board.streakOf(agent) == 0, "streak should read lapsed after a gap");
        _prank(agent);
        board.checkIn();
        require(board.streakOf(agent) == 1, "streak should restart at 1");
        require(board.totalOf(agent) == 3, "total should be 3");
        require(board.uniqueAgents() == 1, "still one unique agent");
    }
}
