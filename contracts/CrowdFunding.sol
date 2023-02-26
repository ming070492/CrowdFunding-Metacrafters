// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//------ creating interface to accept a custom ERC20 token ------ //

interface IERC20 {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

//------ smart contract start ------ //

contract CrowdFunding {
    //------- struct to keep track details of all the campaigns ------ //

    struct Campaign {
        address creatorAddress;
        uint256 fundGoal;
        uint256 pledged;
        uint256 startAt;
        uint256 endAt;
        bool fundClaimed;
    }

    //----- custom (token) USTD to be collected ------ //

    IERC20 public immutable token;

    //----- count number of the campaigns ------ //

    uint256 public countCampaign;

    //----- maximum duration of campaign ------ //

    uint256 public maximumDuration;

    //----- mapping campaigns with unique id ------ //

    mapping(uint256 => Campaign) public campaigns;

    //----- mapping - how much amount got from which account ------ //

    mapping(uint256 => mapping(address => uint256)) public pledgedAmmount;

    //----- event emitting- launch of a campaign  ------ //

    event Launch(
        uint256 id,
        address indexed creatorAddress,
        uint256 fundGoal,
        uint32 startAt,
        uint32 endAt
    );
    //----- event to cancel a campaign ------ //

    event Cancel(uint256 id);

    //----- event to pledge a campaign ------ //

    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);

    //----- event to unpledge a campaign ------ //

    event Unpledge(uint256 indexed id, address indexed caller, uint256 amount);

    //----- event to claim the amount ------ //

    event Claim(uint256 id);

    //----- event refund ------ //

    event Refund(uint256 id, address indexed caller, uint256 amount);

    //----- initializing immutable variable via the constructor ------ //

    constructor(address _token, uint256 _maximumDuration) {
        //----- custom token address like USTD ------ //

        token = IERC20(_token);

        //----- max duration of a campagin ------ //

        maximumDuration = _maximumDuration;
    }

    //-----function to launch new campaign ------ //

    function launch(
        uint256 _fundGoal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(
            _startAt >= block.timestamp,
            "Start time is lesser than current Block Timestamp"
        );
        require(_endAt > _startAt, "End time is lesser than Start time");
        require(
            _endAt <= block.timestamp + maximumDuration,
            "End time exceeded the max Duration"
        );
        countCampaign += 1;
        campaigns[countCampaign] = Campaign({
            creatorAddress: msg.sender,
            fundGoal: _fundGoal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            fundClaimed: false
        });
        //-----emit launch ------ //

        emit Launch(countCampaign, msg.sender, _fundGoal, _startAt, _endAt);
    }

    //-----   function to cancel any campaign ------ //

    function cancel(uint256 _id) external {
        Campaign memory campaign = campaigns[_id];
        require(
            campaign.creatorAddress == msg.sender,
            "You are not creator of this Campaign"
        );
        require(
            block.timestamp < campaign.startAt,
            "Campaign is already started"
        );
        delete campaigns[_id];

        //-----emit cancel ------ //

        emit Cancel(_id);
    }

    //----- function to pledge a campaign ------ //

    function pledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(
            block.timestamp >= campaign.startAt,
            "Campaign is not Started "
        );
        require(
            block.timestamp <= campaign.endAt,
            "Campaign was already ended"
        );
        campaign.pledged += _amount;
        pledgedAmmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        //-----emit pledge ------ //

        emit Pledge(_id, msg.sender, _amount);
    }

    //-----function to unpledge from a campaign ------ //

    function unPledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Campaign is not Started");
        require(block.timestamp <= campaign.endAt, "Campaign is already ended");
        require(
            pledgedAmmount[_id][msg.sender] >= _amount,
            "not enough tokens for Pledged to withdraw"
        );
        campaign.pledged -= _amount;
        pledgedAmmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        //-----emit unpledge ------ //

        emit Unpledge(_id, msg.sender, _amount);
    }

    //-----function to claim the raised fund ------ //
    function claim(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.creatorAddress == msg.sender,
            "You did not created this Campaign"
        );
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(
            campaign.pledged >= campaign.fundGoal,
            "Campaign not fullfilled"
        );
        require(!campaign.fundClaimed, "Fund Claimed");

        campaign.fundClaimed = true;
        token.transfer(campaign.creatorAddress, campaign.pledged);

        //-----emit claim ------ //

        emit Claim(_id);
    }

    //----- function to refund the amount ------ //

    function refund(uint256 _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "campaign not ended");
        require(
            campaign.pledged < campaign.fundGoal,
            "You cannot Withdraw, Campaign is succeeded"
        );
        uint256 bal = pledgedAmmount[_id][msg.sender];
        pledgedAmmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        //-----emit refund ------ //

        emit Refund(_id, msg.sender, bal);
    }
}
